locals {
    name = "myDeploymentName"
    eks_cluster_name = "MyClusterName"
    cdr_regcred_secret_arn = null
    # cdr_regcred_secret_arn = "arn:aws:secretsmanager:<region>:012345678910:secret:shared/regcred/my.registry.com/username"
    parent_domain = "example.com"
    # If you are not able to create Route53 DNS entries, then set to false
    # You will then need to create your DNS entry manually.
    route53_create_record = true
    region="us-east-1"
}

module "smile_cdr_dependencies" {
  source = "git::https://gitlab.com/smilecdr-public/smile-dh-helm-charts//src/main/terraform/smile-cdr-deps?ref=terraform-module-v1"
  name = local.name
  eks_cluster_name = local.eks_cluster_name
  cdr_regcred_secret_arn = local.cdr_regcred_secret_arn
  prod_mode = false

  # You can leave this as null and it will use the latest version of the Helm Chart.
  # Ideally, you should specify the Helm Chart version that you require
  # helm_chart_version = "1.1.1"

  helm_chart_values = [
    file("helm/smilecdr/values.yaml"),
    file("helm/smilecdr/feature1.yaml")
  ]

  helm_chart_mapped_files = [
    {
      name = "file1.txt"
      location = "classes"
      data = file("files/classes/file1.txt")
    },
    {
      name = "file2.txt"
      location = "customerlib"
      data = file("files/customerlib/file2.txt")
    }
  ]

  ingress_config = {
    public = {
      route53_create_record = local.route53_create_record
      parent_domain = local.parent_domain
    }
  }
}

output "helm_release_notes" {
  value = module.smile_cdr_dependencies.helm_release_notes
}
