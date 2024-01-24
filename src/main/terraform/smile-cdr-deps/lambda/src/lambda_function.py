# Copyright 2018 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

import re
import boto3
from botocore.exceptions import ClientError
import time
import json
import logging
import os
import psycopg2

logger = logging.getLogger()
logger.setLevel(logging.INFO)
# logger.setLevel(logging.DEBUG)

MAX_RDS_DB_INSTANCE_ARN_LENGTH = 256


def lambda_handler(event, context):
    """Postgres User & DB creator

    This handler uses the master-user rotation scheme to rotate an RDS PostgreSQL user credential. During the first rotation, this
    scheme logs into the database as the master user, creates a new user (appending _clone to the username), and grants the
    new user all of the permissions from the user being rotated. Once the secret is in this state, every subsequent rotation
    simply creates a new secret with the AWSPREVIOUS user credentials, changes that user's password, and then marks the
    latest secret as AWSCURRENT.

    The Secret SecretString is expected to be a JSON string with the following format:
    {
        'engine': <required: must be set to 'postgres'>,
        'host': <required: instance host name>,
        'username': <required: username>,
        'password': <optional: password>,
        'dbname': <required: database name, default to 'postgres'>,
        'port': <optional: if not specified, default port 5432 will be used>,
        'masterarn': <required: the arn of the master secret which will be used to create users/change passwords>
    }

    Args:
        event (dict): Lambda dictionary of event parameters. These keys must include the following:
            - SecretId: The secret ARN or identifier
            - ClientRequestToken: The ClientRequestToken of the secret version
            - Step: The rotation step (one of createSecret, setSecret, testSecret, or finishSecret)

        context (LambdaContext): The Lambda runtime information

    Raises:
        ResourceNotFoundException: If the secret with the specified arn and stage does not exist

        ValueError: If the secret is not properly configured for rotation

        KeyError: If the secret json does not contain the expected keys

    """
    secretArn = event['SecretId']
    # token = event['ClientRequestToken']
    # step = event['Step']

    # endpoint_url="https://secretsmanager.us-east-1.amazonaws.com"

    # Determine the ARN of the IAM Role used by this Lambda function.
    sts_client = boto3.client('sts')
    assumed_role_arn = sts_client.get_caller_identity().get('Arn')
    arn_parts = assumed_role_arn.split(':')
    account_id = arn_parts[4]
    lambda_role_name = arn_parts[5].split('/')[1]
    lambda_role_arn = f"arn:aws:iam::{account_id}:role/{lambda_role_name}"

    # Setup the client
    # service_client = boto3.client('secretsmanager', endpoint_url=os.environ['SECRETS_MANAGER_ENDPOINT'])
    # service_client = boto3.client('secretsmanager', endpoint_url=endpoint_url)
    service_client = boto3.client('secretsmanager')

    # Setup the RDS client
    rds_client = boto3.client('rds')

    # Get the current version of the passed in user secret
    user_dict = get_secret_dict(service_client, secretArn, "AWSCURRENT")

    # Get the authentication type from the tags.
    # IMPORTANT: This should be after get_secret_dict as that fn will block until the
    # necessary IAM roles have propagated.
    metadata = service_client.describe_secret(SecretId=secretArn)
    auth_type = "password"
    for tag in metadata['Tags']:
        if tag['Key'].lower() == 'auth_type':
            auth_type = tag['Value']

    if auth_type == 'iam':
        # User/Pass authentication failed. Let's try IAM authentication.
        # Update password with token if using IAM
        logger.info("Using IAM auth")
        user_dict_iam = user_dict.copy()
        user_dict_iam['password'] = rds_client.generate_db_auth_token(DBHostname=user_dict['host'], Port=user_dict['port'], DBUsername=user_dict['username'])

        conn = get_connection(user_dict_iam)
        if conn:
            conn.close()
            logger.info("CreateUserAndDB: User and database are already configured and working in PostgreSQL DB with IAM authentication.")
            return
    else:
        # Add error handling in case it cannot connect to DB...
        logger.info("Testing connection to DB with user credentials...")
        # Test connection to DB using user credentials
        conn = get_connection(user_dict)
        if conn:
            conn.close()
            logger.info(f"CreateUserAndDB: User and database are already configured and working in PostgreSQL DB for secret arn {secretArn}")
            return



    master_arn = user_dict['masterarn']
    master_dict = get_secret_dict(service_client, master_arn, "AWSCURRENT", True)

    if user_dict['host'] != master_dict['host']:
        logger.error("CreateUserAndDB: The `host` field differs in user secret %s and master secret %s" % secretArn, master_arn)
        raise ValueError("Host field differs in user secret %s and master secret %s" % secretArn, master_arn)

    # Log into the database with the master credentials to set user & db
    logger.info("Connecting to DB with master credentials...")
    master_conn = get_connection(master_dict)

    if not master_conn:
        logger.error("CreateUserAndDB: Unable to log into database using credentials in master secret %s" % master_arn)
        raise ValueError("Unable to log into database using credentials in master secret %s" % master_arn)


    # Now check to see if user is present and create it if not.
    # CREATE ROLE cdrdev_clustermgr WITH LOGIN PASSWORD 'strongpassword' CREATEDB;
    try:
        with master_conn.cursor() as cur:
            # Get escaped username via quote_ident
            cur.execute("SELECT quote_ident(%s)", (master_dict['username'],))
            master_username = cur.fetchone()[0]
            cur.execute("SELECT quote_ident(%s)", (user_dict['username'],))
            username = cur.fetchone()[0]
            cur.execute("SELECT quote_ident(%s)", (user_dict['dbname'],))
            dbname = cur.fetchone()[0]

            # logger.info(dbname)

            # Check if the user exists, if not create it.
            # If the user exists, just update the password
            cur.execute("SELECT 1 FROM pg_roles where rolname = %s", (user_dict['username'],))
            if len(cur.fetchall()) == 0:
                create_role = "CREATE ROLE %s" % username
                cur.execute(create_role + " WITH LOGIN PASSWORD %s", (user_dict['password'],))
                # cur.execute(f"CREATE ROLE {username} WITH LOGIN PASSWORD %s", (user_dict['password']))
                # cur.execute("GRANT " + username + " TO " + master_username)
                # cur.execute("GRANT %s TO %s" % (current_username, pending_username))

                if auth_type == "iam":
                    # Add to the rds_iam role
                    logger.info(f"CreateUserAndDB: Enabling IAM auth for user: {user_dict['username']} in PostgreSQL DB for secret arn {secretArn}.")
                    cur.execute(f"GRANT rds_iam TO {username}")
                logger.info("CreateUserAndDB: Successfully created user %s in PostgreSQL DB for secret arn %s." % (user_dict['username'], secretArn))
            else:
                if auth_type == "iam":
                    # Add to the rds_iam role
                    logger.info(f"CreateUserAndDB: Enabling IAM auth for user: {user_dict['username']} in PostgreSQL DB for secret arn {secretArn}.")
                    cur.execute(f"GRANT rds_iam TO {username}")
                else:
                    # Remove the rds_iam role
                    logger.info(f"CreateUserAndDB: Disabling IAM auth for user: {user_dict['username']} in PostgreSQL DB for secret arn {secretArn}.")
                    cur.execute(f"REVOKE rds_iam FROM {username}")
                    alter_role = "ALTER USER %s" % username
                    cur.execute(alter_role + " WITH PASSWORD %s", (user_dict['password'],))
                    logger.info(f"CreateUserAndDB: Successfully set password for {user_dict['username']} in PostgreSQL DB for secret arn {secretArn}.")
            master_conn.commit()

    finally:
        master_conn.close()

    # Log into the database with the master credentials to set user & db
    master_conn = get_connection(master_dict)

    if not master_conn:
        logger.error(f"CreateUserAndDB: Unable to log into database using credentials in master secret {master_arn}")
        raise ValueError(f"Unable to log into database using credentials in master secret {master_arn}")

    try:
        master_conn.autocommit=True
        with master_conn.cursor() as cur:
            # Check if the DB exists, if not create it and grant the permissions to the role
            # CREATE DATABASE cdrdev_clustermgr WITH OWNER cdrdev_clustermgr;
            cur.execute("SELECT 1 FROM pg_database WHERE datname = %s", (user_dict['dbname'],))
            if len(cur.fetchall()) == 0:
                cur.execute(f"CREATE DATABASE {dbname}")
                cur.execute(f"GRANT ALL PRIVILEGES ON DATABASE {dbname} TO {username}")
                cur.execute(f"GRANT ALL PRIVILEGES ON SCHEMA public TO {username}")
                cur.execute(f"GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO {username}")
                cur.execute(f"GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO {username}")
                cur.execute(f"GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO {username}")
                logger.info(f"CreateUserAndDB: Successfully created database {dbname} in PostgreSQL DB for secret arn {secretArn}.")
    except psycopg2.OperationalError as e:
        logger.error(f"Creating database {dbname} in PostgreSQL DB for secret arn {secretArn}. Failed: {e}")
    finally:
        master_conn.close()


    # Test that the connection now works
    if auth_type == "iam":
        # Replace the password with the IAM auth token
        user_dict['password'] = user_dict_iam['password']
        # Use retry logic as this may be due to a delayed IAM policy update if IAM Auth was just enabled for this user.
        max_retries = 3
        base_delay = 2 # seconds
        new_iam_session = None
        for retry_count in range(max_retries):
            conn = get_connection(user_dict)
            if conn:
                conn.close()
                logger.info(f"CreateUserAndDB: User and database have been configured and tested with IAM auth for secret arn {secretArn}")
                break
            else:
                delay = base_delay * (2 ** retry_count)
                logger.info(f"IAM Auth failed. Retrying in {delay} seconds.")
                time.sleep(delay)
                # Update token before continuing...
                # This needs to be done with a fresh set of credentials so that the current IAM role/policies are used. If you do not do this
                # then it takes 300 seconds (5 minutes) for the current session to pick up the new policies.
                # In order to get the fresh credentials, we must use sts assumeRole, as the default session uses environment-based credentials
                # that last for the duration of the Lambda function. Any new sessions will use these same credentials, resulting in an invalid
                # token.

                session_name = "testing"
                response = sts_client.assume_role(RoleArn=lambda_role_arn, RoleSessionName = session_name)

                new_credentials = response['Credentials']

                new_iam_session = boto3.session.Session(
                    aws_access_key_id=new_credentials['AccessKeyId'],
                    aws_secret_access_key=new_credentials['SecretAccessKey'],
                    aws_session_token=new_credentials['SessionToken'],
                )
                rds_client.close()
                rds_client = new_iam_session.client('rds')
                user_dict['password'] = rds_client.generate_db_auth_token(DBHostname=user_dict['host'], Port=user_dict['port'], DBUsername=user_dict['username'])
        else:
            # Max retries reached, fail
            logger.error(f"CreateUserAndDB: User and database have been configured for IAM auth, but still unable to log in.")
            raise ValueError(f"Unable to log into database with IAM auth for secret ARN {secretArn}")

    else:
        conn = get_connection(user_dict)
        if conn:
            conn.close()
            logger.info(f"CreateUserAndDB: User and database have been configured and tested with password auth for secret arn {secretArn}")
        else:
            logger.error(f"CreateUserAndDB: User and database have been configured for password auth, but still unable to log in with current secret from secret ARN {secretArn}")
            raise ValueError(f"Unable to log into database with current secret of secret ARN {secretArn}")

def get_connection(secret_dict):
    """Gets a connection to PostgreSQL DB from a secret dictionary

    This helper function uses connectivity information from the secret dictionary to initiate
    connection attempt(s) to the database. Will attempt a fallback, non-SSL connection when
    initial connection fails using SSL and fall_back is True.

    Args:
        secret_dict (dict): The Secret Dictionary

    Returns:
        Connection: The The psycopg.Connection object if successful. None otherwise

    Raises:
        KeyError: If the secret json does not contain the expected keys

    """
    # Parse and validate the secret JSON string
    port = int(secret_dict['port']) if 'port' in secret_dict else 5432
    dbname = secret_dict['dbname'] if 'dbname' in secret_dict else "postgres"

    # Get SSL connectivity configuration
    use_ssl, fall_back = get_ssl_config(secret_dict)

    # if an 'ssl' key is not found or does not contain a valid value, attempt an SSL connection and fall back to non-SSL on failure
    conn = connect_and_authenticate(secret_dict, port, dbname, use_ssl=use_ssl)
    if conn or not fall_back:
        return conn
    else:
        return connect_and_authenticate(secret_dict, port, dbname, use_ssl=False)


def get_ssl_config(secret_dict):
    """Gets the desired SSL and fall back behavior using a secret dictionary

    This helper function uses the existance and value the 'ssl' key in a secret dictionary
    to determine desired SSL connectivity configuration. Its behavior is as follows:
        - 'ssl' key DNE or invalid type/value: return True, True
        - 'ssl' key is bool: return secret_dict['ssl'], False
        - 'ssl' key equals "true" ignoring case: return True, False
        - 'ssl' key equals "false" ignoring case: return False, False

    Args:
        secret_dict (dict): The Secret Dictionary

    Returns:
        Tuple(use_ssl, fall_back): SSL configuration
            - use_ssl (bool): Flag indicating if an SSL connection should be attempted
            - fall_back (bool): Flag indicating if non-SSL connection should be attempted if SSL connection fails

    """
    # Default to True for SSL and fall_back mode if 'ssl' key DNE
    if 'ssl' not in secret_dict:
        return True, True

    # Handle type bool
    if isinstance(secret_dict['ssl'], bool):
        return secret_dict['ssl'], False

    # Handle type string
    if isinstance(secret_dict['ssl'], str):
        ssl = secret_dict['ssl'].lower()
        if ssl == "true":
            return True, False
        elif ssl == "false":
            return False, False
        else:
            # Invalid string value, default to True for both SSL and fall_back mode
            return True, True

    # Invalid type, default to True for both SSL and fall_back mode
    return True, True


def connect_and_authenticate(secret_dict, port, dbname, use_ssl):
    """Attempt to connect and authenticate to a PostgreSQL instance

    This helper function tries to connect to the database using connectivity info passed in.
    If successful, it returns the connection, else None

    Args:
        - secret_dict (dict): The Secret Dictionary
        - port (int): The databse port to connect to
        - dbname (str): Name of the database
        - use_ssl (bool): Flag indicating whether connection should use SSL/TLS

    Returns:
        Connection: The psycopg.database.Database object if successful. None otherwise

    Raises:
        KeyError: If the secret json does not contain the expected keys

    """
    # Try to obtain a connection to the db
    ssl_message = "SSL/TLS" if use_ssl else "non SSL/TLS"
    logger.info(f"Attempting {ssl_message} connection as user '{secret_dict['username']}' with host: '{secret_dict['host']}'")
    try:
        if use_ssl:
            # Setting sslmode='verify-full' will verify the server's certificate and check the server's host name
            conn = psycopg2.connect(host=secret_dict['host'], user=secret_dict['username'], password=secret_dict['password'], dbname=dbname, port=port,
                                connect_timeout=5, sslrootcert='/etc/pki/tls/cert.pem', sslmode='verify-full')
        else:
            conn = psycopg2.connect(host=secret_dict['host'], user=secret_dict['username'], password=secret_dict['password'], dbname=dbname, port=port,
                                connect_timeout=5, sslmode='disable')

        logger.info(f"Successfully established {ssl_message} connection as user '{secret_dict['username']}' with host: '{secret_dict['host']}'")
        return conn
    except psycopg2.OperationalError as e:
        if "server does not support SSL, but SSL was required" in e.args[0]:
            logger.error("Unable to establish SSL/TLS handshake, SSL/TLS is not enabled on the host: %s" % secret_dict['host'])
        elif re.search('server common name ".+" does not match host name ".+"', e.args[0]):
            logger.error("Hostname verification failed when estlablishing SSL/TLS Handshake with host: %s" % secret_dict['host'])
        elif re.search('no pg_hba.conf entry for host ".+", SSL off', e.args[0]):
            logger.error("Unable to establish SSL/TLS handshake, SSL/TLS is enforced on the host: %s" % secret_dict['host'])
        elif re.search('sslmode value', e.args[0]):
            logger.error(f'SSL Mode error: {e.args[0]}')
        elif re.search('password authentication failed', e.args[0]):
            logger.error(f"Password Login Failed for user: {secret_dict['username']} with host: {secret_dict['host']}\nError: {e.args[0]}")
        elif re.search('PAM authentication failed', e.args[0]):
            # This occurs when attempting to use password auth when user is configured
            # for IAM auth.
            logger.error(f"Password Login Failed for user: {secret_dict['username']} with host: {secret_dict['host']}\nError: {e.args[0]}")
        elif re.search('pg_hba.conf rejects connection for host', e.args[0]):
            # This occurs when attempting to send IAM auth token when not configured
            # for the user.
            logger.error(f"IAM Login Failed for user: {secret_dict['username']} with host: {secret_dict['host']}\nError: {e.args[0]}")
        elif re.search('out of memory', e.args[0]):
            # This is a VERY misleading error that occurs when IAM auth is attempted
            # for a user that is not yet configured for IAM auth. See this related issue here:
            # https://github.com/DataDog/integrations-core/issues/16175#issuecomment-1811034553
            logger.error(f"IAM Authentication Failed for user {secret_dict['username']} with host: {secret_dict['host']}")
        else:
            logger.error("Unhandled Exception in connection: %s" % e)
            raise
        return None


def get_secret_dict(service_client, secret_arn, stage, master_secret=False):
    """Gets the secret dictionary corresponding for the secret arn, stage, and token

    This helper function gets credentials for the arn and stage passed in and returns the dictionary by parsing the JSON string

    Args:
        service_client (client): The secrets manager service client

        arn (string): The secret ARN or other identifier

        stage (string): The stage identifying the secret version

        master_secret (boolean): A flag that indicates if we are getting a master secret.

    Returns:
        SecretDictionary: Secret dictionary

    Raises:
        ResourceNotFoundException: If the secret with the specified arn and stage does not exist

        ValueError: If the secret is not valid JSON

        KeyError: If the secret json does not contain the expected keys

    """
    required_fields = ['host', 'username', 'password', 'engine', 'dbname']

    if not master_secret:
        required_fields.append('masterarn')

    # Retry configuration to avoid race condition where lambda is called just after a new Secret
    # ARN has been added to the IAM policy. It takes a short while for the policy to propagate.
    # This will retry until the policy has propagated and access is granted.
    # In the event that there is a mis-configuration and the policy is incorrect, this retry logic
    # will give up and raise the error after 20s.
    max_retries = 3
    base_delay = 3 # seconds

    last_exception = None
    for retry_count in range(max_retries):
        try:
            secret = service_client.get_secret_value(SecretId=secret_arn, VersionStage=stage)
            # Exit the loop if successful
            break
        except ClientError as e:
            if e.response['Error']['Code'] == 'AccessDeniedException':
                delay = base_delay * (2 ** retry_count)
                print(f"Access denied. Retrying in {delay} seconds.")
                time.sleep(delay)
                last_exception = e
            else:
                # Handle other exceptions or re-raise if needed
                raise
    else:
        # Max retries reached, re-raise the exception to fail the function
        if last_exception is not None:
            print(f"Max retries reached. Unable to retrieve secret '{secret_arn}'.")
            raise last_exception

    plaintext = secret['SecretString']
    secret_dict = json.loads(plaintext)

    # Run validations against the secret
    if master_secret and (set(secret_dict.keys()) == set(['username', 'password'])):
        # If this is an RDS-made Master Secret, we can fetch `host` and other connection params
        # from the DescribeDBInstances RDS API using the DB Instance ARN as a filter.
        # The DB Instance ARN is fetched from the RDS-made Master Secret's System Tags.
        db_arn = fetch_db_arn_from_system_tags(service_client, secret_arn, )
        if db_arn is not None:
            secret_dict = get_connection_params_from_rds_api(secret_dict, db_arn)
            logger.info("setSecret: Successfully fetched connection params for Master Secret %s from DescribeDBInstances API." % secret_arn)

        # For non-RDS-made Master Secrets that are missing `host`, this will error below when checking for required connection params.

    for field in required_fields:
        if field not in secret_dict:
            raise KeyError("%s key is missing from secret JSON" % field)

    if not 'postgres' in secret_dict['engine']:
        raise KeyError("Database engine must be set to 'postgres' in order to use this db/user creation lambda")

    # Parse and return the secret JSON string
    return secret_dict


def is_rds_replica_database(replica_dict, master_dict):
    """Validates that the database of a secret is a replica of the database of the master secret

    This helper function validates that the database of a secret is a replica of the database of the master secret.

    Args:
        replica_dict (dictionary): The secret dictionary containing the replica database

        primary_dict (dictionary): The secret dictionary containing the primary database

    Returns:
        isReplica : whether or not the database is a replica

    Raises:
        ValueError: If the new username length would exceed the maximum allowed
    """
    # Setup the client
    rds_client = boto3.client('rds')

    # Get instance identifiers from endpoints
    replica_instance_id = replica_dict['host'].split(".")[0]
    master_instance_id = master_dict['host'].split(".")[0]

    try:
        describe_response = rds_client.describe_db_instances(DBInstanceIdentifier=replica_instance_id)
    except Exception as err:
        logger.warning("Encountered error while verifying rds replica status: %s" % err)
        return False
    instances = describe_response['DBInstances']

    # Host from current secret cannot be found
    if not instances:
        logger.info("Cannot verify replica status - no RDS instance found with identifier: %s" % replica_instance_id)
        return False

    # DB Instance identifiers are unique - can only be one result
    current_instance = instances[0]
    return master_instance_id == current_instance.get('ReadReplicaSourceDBInstanceIdentifier')


def fetch_db_arn_from_system_tags(service_client, secret_arn):
    """Fetches DB Instance ARN from the given secret's metadata.

    Fetches DB Instance ARN from the given secret's metadata.

    Args:
        service_client (client): The secrets manager service client

        secret_arn (String): The secret ARN used in a DescribeSecrets API call to fetch the secret's metadata.

    Returns:
        db_instance_arn (String): The DB Instance ARN of the Primary RDS Instance

    """

    metadata = service_client.describe_secret(SecretId=secret_arn)
    tags = metadata['Tags']

    # Check if DB Instance ARN is present in secret Tags
    db_arn = None
    for tag in tags:
        if tag['Key'].lower() == 'aws:rds:primarydbinstancearn':
            db_arn = tag['Value']
        elif tag['Key'].lower() == 'aws:rds:primarydbclusterarn':
            db_arn = tag['Value']

    # DB Instance ARN must be present in secret System Tags to use this work-around
    if db_arn is None:
        logger.warning("setSecret: DB Cluster/Instance ARN not present in Metadata System Tags for secret %s" % secret_arn)
    elif len(db_arn) > MAX_RDS_DB_INSTANCE_ARN_LENGTH:
        logger.error("setSecret: %s is not a valid DB Instance ARN. It exceeds the maximum length of %d." % (db_arn, MAX_RDS_DB_INSTANCE_ARN_LENGTH))
        raise ValueError("%s is not a valid DB Instance ARN. It exceeds the maximum length of %d." % (db_arn, MAX_RDS_DB_INSTANCE_ARN_LENGTH))

    return db_arn


def get_connection_params_from_rds_api(master_dict, db_arn):
    """Fetches connection parameters (`host`, `port`, etc.) from the DescribeDBInstances RDS API using `db_arn` in the master secret metadata as a filter.

    This helper function fetches connection parameters from the DescribeDBInstances RDS API using `db_arn` in the master secret metadata as a filter.

    Args:
        master_dict (dictionary): The master secret dictionary that will be updated with connection parameters.

        db_arn (string): The DB Instance ARN from master secret System Tags that will be used as a filter in DescribeDBInstances RDS API calls.

    Returns:
        master_dict (dictionary): An updated master secret dictionary that now contains connection parameters such as `host`, `port`, etc.

    Raises:
        Exception: If there is some error/throttling when calling the DescribeDBInstances RDS API

        ValueError: If the DescribeDBInstances RDS API Response contains no Instances or more than 1 Instance
    """
    # Setup the client
    rds_client = boto3.client('rds')

    # If arn is for a DB Instance (i.e. contains `:db:`)
    if ':db:' in db_arn:
        # Call DescribeDBInstances RDS API
        try:
            describe_response = rds_client.describe_db_instances(DBInstanceIdentifier=db_arn)
        except Exception as err:
            logger.error("setSecret: Encountered API error while fetching connection parameters from DescribeDBInstances RDS API: %s" % err)
            raise Exception("Encountered API error while fetching connection parameters from DescribeDBInstances RDS API: %s" % err)

        # Verify the instance was found
        instances = describe_response['DBInstances']
        if len(instances) == 0:
            logger.error("setSecret: %s is not a valid DB Instance ARN. No Instances found when using DescribeDBInstances RDS API to get connection params." % db_arn)
            raise ValueError("%s is not a valid DB Instance ARN. No Instances found when using DescribeDBInstances RDS API to get connection params." % db_arn)

        # put connection parameters in master secret dictionary
        primary_instance = instances[0]
        master_dict['host'] = primary_instance['Endpoint']['Address']
        master_dict['port'] = primary_instance['Endpoint']['Port']
        master_dict['dbname'] = primary_instance.get('DBName', 'postgres')  # `DBName` doesn't have to be present.
        master_dict['engine'] = primary_instance['Engine']

    # If arn is for a DB Cluster (i.e. contains `:cluster:`)
    elif ':cluster:' in db_arn:
        # Call DescribeDBInstances RDS API
        try:
            describe_response = rds_client.describe_db_clusters(DBClusterIdentifier=db_arn)
        except Exception as err:
            logger.error("setSecret: Encountered API error while fetching connection parameters from DescribeDBClusters RDS API: %s" % err)
            raise Exception("Encountered API error while fetching connection parameters from DescribeDBClusters RDS API: %s" % err)

        # Verify the instance was found
        clusters = describe_response['DBClusters']
        if len(clusters) == 0:
            logger.error("setSecret: %s is not a valid DB Cluster ARN. No Instances found when using DescribeDBClusters RDS API to get connection params." % db_arn)
            raise ValueError("%s is not a valid DB Instance ARN. No Instances found when using DescribeDBClusters RDS API to get connection params." % db_arn)

        # put connection parameters in master secret dictionary
        primary_cluster = clusters[0]
        master_dict['host'] = primary_cluster['Endpoint']
        master_dict['port'] = primary_cluster['Port']
        master_dict['dbname'] = primary_cluster.get('DBName', 'postgres')  # `DBName` doesn't have to be present.
        master_dict['engine'] = primary_cluster['Engine']

    return master_dict
