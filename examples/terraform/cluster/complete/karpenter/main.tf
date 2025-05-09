################################################################################
# Example EKS Cluster Terraform Project
################################################################################
#
# Modify values in this locals block to modify the behaviour of this Terraform project
#

locals {

  ################################################################################
  # General Settings
  ################################################################################
  #
  # Provide EKS Cluster Name and AWS region
  #
  name   = "MyClusterName"
  region = "us-east-1"

  ################################################################################
  # Ingress Settings
  ################################################################################
  #
  # Provide Ingress and TLS settings if using ingress-nginx (The default)
  #
  enable_nginx_ingress = true
  nginx_ingress = {
    enable_tls = true
    # If Nginx Ingress and TLS are both enabled, you MUST provide a TLS certificate via ACM.
    #
    # Note that this project has NOT been tested without enabling TLS, so it's advised to
    # provide the certificate arn as follows:
    #
    # acm_cert_arn = "arn:aws:acm:us-east-1:012345678910:certificate/xxxx-yyyy-zzzz"
    acm_cert_arn = null
  }

  ################################################################################
  # VPC Configuration
  ################################################################################
  #
  # By default, this project will create a VPC with 3 subnet tiers, tagged per the
  # documentation located here:
  #
  # https://smilecdr-public.gitlab.io/smile-dh-helm-charts/latest/quickstart-aws/eks-cluster/
  #
  ### Bring Your Own VPC ###
  #
  # If you are deploying to an existing VPC created through other means, set
  # `existing_vpc_id` to that VPC, i.e.
  #
  #   existing_vpc_id = "vpc-0abc123"
  #
  # IMPORTANT! Ensure that you set appropriate tags for Subnet auto-discovery as
  # per the above docs as this solution will not work without appropriately tagged
  # subnets.
  existing_vpc_id = null

  ### Private Subnet Selection ###
  #
  # When using an existing VPC, you can either set the private subnets using
  # auto-discovery or you can manually configure them by providing subnet ids.
  # Refer to the QuickStart docs above for more information on subnet auto discovery.
  private_subnet_discovery_tags = {
    Tier = "Private"
  }
  # existing_private_subnet_ids = ["subnet-0abc123", "subnet-0def456"]
  existing_private_subnet_ids = null
}
