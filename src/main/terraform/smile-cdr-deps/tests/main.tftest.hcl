variables {
	unit_testing = true
  resourcenames_suffix = "testrandom"
  eks_cluster_name = "unittest"
	mock_data_aws_eks_cluster = {
		arn                       = "arn:aws:eks:us-east-1:012345678910:cluster/testcluster"
		identity = [{
			oidc = [{issuer = "https://oidc.eks.us-east-1.amazonaws.com/id/TESTISSUERID1234"}]
	  }]
    vpc_config = [{
      cluster_security_group_id = "sg-0e8a19e0698b16b32"
      vpc_id                    = "vpc-0e3f1b4b61999d0c8"
    }]
  }

  mock_data_aws_iam_openid_connect_provider = {
	  arn                       = "arn:aws:eks:us-east-1:012345678910:cluster/testcluster"
  }

# From examples:
  // mock_data_aws_eks_cluster = {
  //   arn                       = "arn:aws:eks:us-east-1:012345678910:cluster/testcluster"
  //   identity = [{
  //     oidc = [{issuer = "https://oidc.eks.us-east-1.amazonaws.com/id/TESTISSUERID1234"}]
  //   }]

  //   vpc_config = [{
  //     cluster_security_group_id = "sg-0e8a19e0698b16b32"
  //     vpc_id                    = "vpc-0e3f1b4b61999d0c8"
  //   }]
  // }

  // mock_data_aws_iam_openid_connect_provider = {
  //     arn                       = "arn:aws:eks:us-east-1:012345678910:cluster/testcluster"
  // }


  // db_instance_defaults = {
  //   # engine = "aurora-postgresql-serverless-v2"
  //   # db_subnet_ids = ["my_db_subnet_id-1","my_db_subnet_id-2"]
  //   db_subnet_group_name = "temp"
  //   db_subnet_discovery_enabled = false
  //   # Or you can specify autodiscovery subnet tags like so:
  //   # db_subnet_discovery_tags = {
  //   #   Tier = "Database"
  //   # }

      // # TODO: Work out the public logic
      // # publicly_accessible = true
      // # public_cidr_blocks = ["108.175.225.215/32"]
      // # default_auth_type = "iam"

  // }


}

provider "aws" {
}

run "null_config" {
	command = plan

	variables {
		name = "UnitTest-name"
		enable_cdr_regcred_secret = false
	}

	assert {
		condition = ! local.iam_role_enabled
		error_message = "Iam role is created but should not be"
	}
}

run "default_config" {
    command = plan

    variables {
      name = "UnitTest-name"
    }

    assert {
      condition = local.iam_role_enabled
      error_message = "Iam role not flagged for creation"
    }

    assert {
      condition = local.cdr_irsa_role_name == "${var.name}-smilecdr-${var.resourcenames_suffix}"
      error_message = "IRSA role name incorrect"
    }

    assert {
      condition = local.create_secrets
      error_message = "No default secrets created"
    }

    assert {
      condition = local.eks_cluster_oidc_provider_url == var.mock_data_aws_eks_cluster.identity[0].oidc[0].issuer
      error_message = "Error"
    }

    assert {
      condition = local.eks_cluster_oidc_provider_arn == var.mock_data_aws_iam_openid_connect_provider.arn
      error_message = "Error"
    }

    assert {
      condition = local.eks_cluster_endpoint == var.mock_data_aws_eks_cluster.endpoint
      error_message = "Error"
    }

    assert {
      condition = local.eks_cluster_version == var.mock_data_aws_eks_cluster.version
      error_message = "Error"
    }

    assert {
      condition = local.eks_cluster_security_group_id == var.mock_data_aws_eks_cluster.vpc_config[0].cluster_security_group_id
      error_message = "Error"
    }

    assert {
      condition = local.db_vpc_id == var.mock_data_aws_eks_cluster.vpc_config[0].vpc_id
      error_message = "Error"
    }

    assert {
      condition = local.create_secrets_kms
      error_message = "Error"
    }

    assert {
      condition = local.cdr_namespace_service_accounts[0] == "smilecdr:${lower(var.name)}-smilecdr"
      error_message = "Error"
    }

    // assert {
    //   condition =
    //   error_message = "Error"
    // }

    // create_secrets_kms


}
