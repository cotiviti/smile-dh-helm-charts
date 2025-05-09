output "validation" {
  description = "This is not a real output, but used for validation"
  value = null
  precondition {
    condition = local.create_vpc || length(data.aws_subnet.all_existing) > 0
    error_message = "Using existing VPC but no valid subnets have been configured or detected!"
  }
  precondition {
    condition = local.enable_nginx_ingress && local.nginx_ingress.enable_tls ? (
        local.nginx_ingress.acm_cert_arn == null ? false : true
      ):(
        true
      )
    error_message = "Nginx ingress is enabled with TLS, but no ACM certificate has been provided!"
  }
}

output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = "aws eks --region ${local.region} update-kubeconfig --name ${module.eks.cluster_name}"
}

output "debug_output" {
  description = "Various object outputs for debugging purposes. Enable and disable as required."
  value = local.debug_output ? {
    # vpc_details = data.aws_vpc.vpc
    private_subnets = local.private_subnet_ids
    existing_subnet_details = data.aws_subnet.all_existing
    azs = local.azs
    # karpenter = module.karpenter
    # nodeGroup = local.core_node_group_name
  } : null
}
