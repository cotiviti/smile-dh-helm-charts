######################################
### IAM - Lambda DB
######################################

module "lambda_function" {
  count = local.create_rds_user_mgmt_lambda ? 1 : 0
  source  = "terraform-aws-modules/lambda/aws"
  version = "6.4.0"

  publish = true

  function_name = local.lambda_function_name
  # Name = local.lambda_role_name
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.8"

  timeout       = 30

  vpc_subnet_ids         = local.private_subnet_ids
  vpc_security_group_ids = local.lambda_security_group_ids

  role_permissions_boundary = var.permission_boundary_arn

  attach_policies = true
  policies = local.lambda_role_policy_arns
  number_of_policies = length(local.lambda_role_policy_arns)

  # Assume role policy to allow the role to assume itself to get a fresh role session.
  # This is to get around the 5 minute delay before an existing role session will generate
  # valid RDS IAM Auth tokens after the `rds-db:connect` policy statement has been updated.
  assume_role_policy_statements = {
    assume_self = {
      effect  = "Allow",
      actions = ["sts:AssumeRole"],
      principals = {
        account_principal = {
          type        = "AWS",
          identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
        }
      }

      # We need to allow root principal on the assume role policy, and then have a condition below.
      # This is because you can't have a Principal that does not exist, which is not a problem when
      # updating an existing role, but will fail when creating the role.
      condition = {
        stringequals_condition = {
          test     = "StringEqualsIfExists"
          variable = "aws:PrincipalArn"
          values   = [local.lambda_role_arn]
        }
      }
    }
  }

  attach_network_policy = true

  attach_cloudwatch_logs_policy = true

  # create_package         = false
  # local_existing_package = "${path.module}/lambda/zip/psql-user-db-create.zip"
  source_path = "${path.module}/lambda/src/"

}

# data "archive_file" "lambda" {
#   type        = "zip"
#   source_file = "lambda.js"
#   output_path = "lambda_function_payload.zip"
# }

module "lambda_security_group" {
  count = local.create_rds_user_mgmt_lambda ? 1 : 0
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name        = "${local.name}-db-mgmt-${local.resourcenames_suffix}"
  description = "Used by Lambda to create users in database"
  vpc_id      = local.db_vpc_id

  egress_rules = ["all-all"]
}

# TODO: Think about if this should live in the root of this module, or in the pgdb
#       SubModule as it's related to each user.
#       We cannot put the lambda creation in the submodule, as we only want a single
#       lambda function. It's only the invocations that we want for each db user.
resource "aws_lambda_invocation" "create_app_user" {
  for_each = module.postgres_db_user
  function_name = local.lambda_function_name

  terraform_key = "tf"

  input = jsonencode(
        {
          SecretId = each.value.secret_arn
        })

  # TODO: Refactor this out
  triggers = {
    updateUserSecrets = sha1(jsonencode([
      local.secret_versions_db_users
    ]))
    updateAuthType = each.value.auth_type
  }

  # lifecycle_scope = "CRUD"
  lifecycle_scope = "CREATE_ONLY"

  depends_on = [
    module.lambda_function,
    # TODO: This needs to be dependent on something more specific. For now, this only
    #       works for if a single DB instance is created.
    module.managed_database[0]
  ]
}

# We need a policies that allow the Lambda execution role to assume itself to perform RDS IAM authentication.
# This is due to a race condition that fails when enabling IAM auth for an RDS user. If the IAM
# Policy is updated (adding the 'rds-db:connect') just before the Lambda is triggered, then
# It takes 5 minutes for the Lambda's role session to see the updated policy and generate a
# valid auth token.
# By retrying assumption of this role, it's able to generate a valid RDS Auth token a few
# seconds after the policy update.

# We need to manually specify the Lambda role name to avoid circular dependencies. This is done
# in `locals.tf`

resource "aws_iam_policy" "lambda_assume_self" {
  count = length(local.iam_db_user_arns) > 0 ? 1 : 0
  name        = "${local.name}-assume-self-${local.resourcenames_suffix}"
  description = "Smile CDR Policy to allow Lambda role to assume itself to get new IAM role session"
  policy = data.aws_iam_policy_document.lambda_assume_self[0].json
  tags = local.tags
}
data "aws_iam_policy_document" "lambda_assume_self" {
  count = length(local.iam_db_user_arns) > 0 ? 1 : 0
  version = "2012-10-17"

  statement {
    effect = "Allow"
    actions = [
        "sts:AssumeRole"
      ]
    resources = [
        local.lambda_role_arn
    ]
  }
}
