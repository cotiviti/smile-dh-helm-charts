locals {
  example_eks_cluster_data_output = {
    arn                       = "arn:aws:eks:us-west-2:547682466071:cluster/testclient"
    certificate_authority     = [
          {data = "mock-certificate-authority"}
        ]
    created_at                = "2023-02-22 23:32:47.008 +0000 UTC"
    enabled_cluster_log_types = ["api","audit","authenticator"]
    endpoint                  = "https://5F1328919DF8CCDBB4E07C06AA28DF64.gr7.us-west-2.eks.amazonaws.com"
    id                        = "testclient"
    identity = [{
        oidc = [{issuer = "https://oidc.eks.us-west-2.amazonaws.com/id/5F1328919DF8CCDBB4E07C06AA28DF64"}]
      }]
    kubernetes_network_config = [{
        ip_family         = "ipv4"
        service_ipv4_cidr = "172.20.0.0/16"
        service_ipv6_cidr = ""
      }]
    name                      = "testclient"
    outpost_config            = []
    platform_version          = "eks.6"
    role_arn                  = "arn:aws:iam::547682466071:role/testclient-cluster-20230222233222985100000001"
    status                    = "ACTIVE"
    version = "1.28"
    vpc_config = [{
      cluster_security_group_id = "sg-0e8a19e0698b16b32"
      endpoint_private_access   = true
      endpoint_public_access    = true
      public_access_cidrs       = [
          "0.0.0.0/0",
        ]
      security_group_ids        = []
      subnet_ids                = [
          "subnet-07c64c2d13c24df14",
          "subnet-08e8e58480813ae02",
          "subnet-0d294e3ca2a6bd37f",
        ]
      vpc_id                    = "vpc-0e3f1b4b61999d0c8"
    }]
  }
}
