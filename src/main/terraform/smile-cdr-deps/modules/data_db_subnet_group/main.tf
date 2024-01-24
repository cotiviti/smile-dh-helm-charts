variable "db_subnet_group_name" {
  description = "The name of the existing db subnet group"
  type        = string
  default     = null
}

data "aws_db_subnet_group" "this" {
    name = var.db_subnet_group_name
}

output "db_subnet_ids" {
  description = "DB Subnets when using existing DB Subnet Group"
  value = data.aws_db_subnet_group.this.subnet_ids
}
