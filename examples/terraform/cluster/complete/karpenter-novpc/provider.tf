terraform {

  # Uncomment and update settings to use S3 backend for Terraform state
  # backend "s3" {
  #   bucket = "terraform-state-backend-012345678910-us-east-1"
  #   dynamodb_table = "terraform-state-backend"
  #   key = "eks/clusters/MyClusterName"
  #   region = "us-east-1"
  # }
}
