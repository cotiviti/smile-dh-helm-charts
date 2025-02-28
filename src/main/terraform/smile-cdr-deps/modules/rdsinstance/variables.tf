# Vars we will need

variable "name" {
  # Want to keep the params to a minimum so it's easy to call
  description = "Name for related resources"
  type        = string
  default     = ""
}

variable "resourcenames_suffix" {
  description = "Set suffix on generated resource names. Will generate random suffix if not set."
  type        = string
  default     = null
}

variable "clustername_override" {
  description = "Set to override DB instance resource"
  type        = string
  default     = null
}

variable "secrets_kms_key_arn" {
  description = "KMS key ARN for secrets"
  type        = string
  default     = ""
}

variable "secrets_rds_master_name" {
  description = "Name to use when creating master secret for RDS instance. Resource suffix will be used"
  type        = string
  default     = "postgres"
}

variable "secrets_rds_master_name_override" {
  description = "Name to use when creating master secret for RDS instance. Overrides any suffix"
  type        = string
  default     = null
}

variable "secrets_deletion_window" {
  description = "Deletion Window for Secrets. Set to 0 for dev environments, or set from 7 to 30"
  type        = number
  default     = 7
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "db_subnet_discovery_tags" {
  description = "Set the tags for subnet auto-discovery"
  type        = map(string)
  default     = null
}

variable "db_subnet_discovery_enabled" {
  description = "Set the tags for subnet auto-discovery"
  type        = bool
  default     = true
  nullable    = false
}

variable "db_subnet_ids" {
  description = "Blash"
  type        = list(string)
  default     = []
  nullable    = false
}
variable "db_subnet_group_name" {
  description = "The name of the db subnet group (existing or created)"
  type        = string
  default     = null
}

# variable "allowed_security_groups" {
#   description = "Blash"
#   type        = list(string)
#   nullable    = false
# }

variable "security_group_rules" {
  description = "Map of security group rules to add to the cluster security group created"
  type        = map(any)
  default     = {}
}

variable "public_cidr_blocks" {
  description = "List of cidr blocks to allow when public access is enabled"
  type        = list(string)
  default     = []
  nullable    = false
}

variable "publicly_accessible" {
  description = "Blash"
  type        = bool
  default     = false
  nullable    = false
}

variable "engine" {
  description = "RDS engine to use"
  type        = string
  default     = "aurora-postgresql-serverless-v2"
  validation {
    condition = contains(["aurora-postgresql-serverless-v2"], var.engine)
    error_message = "Invalid RDS engine. Available options are: \"aurora-postgresql-serverless-v2\""
  }
}

variable "engine_version" {
  description = "RDS engine version to use"
  type        = string
  default     = "14.9"
}

variable "serverless_configuration" {
  description = "Aurora Serverless Configuration"
  type        = object({
    min_capacity = optional(number,0.5)
    max_capacity = optional(number,10)
  })
  default = {
    min_capacity = 0.5
    max_capacity = 10
  }
  
  validation {
    condition = var.serverless_configuration.min_capacity >= 0.5
    error_message = "Serverless `min_capacity` cannot be lower than 0.5"
  }

  validation {
    condition = var.serverless_configuration.max_capacity <= 128
    error_message = "Serverless `max_capacity` cannot be greater than 128"
  }
  validation {
    condition = var.serverless_configuration.min_capacity <= var.serverless_configuration.max_capacity
    error_message = "Serverless `min_capacity` cannot be greater than `max_capacity`"
  }
}

variable "master_username" {
  description = "Name for db master username"
  type        = string
  default     = "root"
  nullable = false
}

variable "dbname" {
  description = "Name for maintenance database. No real need to change this"
  type        = string
  default     = "postgres"
}

variable "dbport" {
  description = "Name for database"
  type        = string
  default     = "5432"
}

variable "default_auth_type" {
  description = "Default authentication type to use for this instance"
  type = string
  nullable    = false
  default     = "password"
  validation {
    condition     = can(regex("^(password|iam|secretsmanager)$",var.default_auth_type))
    error_message = "The RDS authentication method must be `password`, `iam` or `secretsmanager`"
  }
}

variable "iam_database_authentication_enabled" {
  description = "Enable IAM Authentication"
  type        = bool
  default     = false
}

variable "manage_master_user_password" {
  description = "Let RDS manage the master user credentials"
  type        = bool
  default     = true
}

# variable "rotation_lambda_arn" {
#   description = "ARN of secret rotation Lambda function"
#   type        = string
#   default     = ""
# }

variable "rds_kms_arn" {
  description = "ARN for KMS key used for RDS. If not specified, one will be created"
  type        = string
  nullable    = true
  default     = null
}

variable "kms_deletion_window" {
  description = "Deletion Window for KMS. Set from 7 to 30"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Tags to pass include on resources for this module"
  type        = map(any)
  default     = null
}
