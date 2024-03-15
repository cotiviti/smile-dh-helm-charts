# Vars we will need

variable "name" {
  description = "Name for related resources"
  type        = string
  default     = ""
}

variable "resourcenames_suffix" {
  description = "Set suffix on generated resource names. Will generate random suffix if not set."
  type        = string
  default     = null
}

variable "secrets_kms_key_arn" {
  description = "KMS key ARN for secrets"
  type        = string
  default     = ""
}

variable "master_secret_arn" {
  description = "ARN for RDS master credentials secret"
  type        = string
  default     = ""
}

variable "db_host" {
  description = "Hostname for database"
  type        = string
  default     = ""
}

variable "username" {
  description = "Name for db username"
  type        = string
  default     = ""
}

variable "dbname" {
  description = "Name for database"
  type        = string
  default     = ""
}

variable "dbport" {
  description = "Name for database"
  type        = string
  default     = "5432"
}

variable "cdr_modules" {
  description = "The modules that this DB will be used for"
  type        = list(string)
  default     = []
  nullable = false
}

# variable "rotation_lambda_arn" {
#   description = "ARN of secret rotation Lambda function"
#   type        = string
#   default     = ""
# }

# TODO: Maybe refactor this out
variable "secrets_deletion_window" {
  description = "Deletion Window for Secrets. Set to 0 for dev environments, or set from 7 to 30"
  type        = number
  default     = 7
}

variable "force_secret_update" {
  description = "Update secret if credentials change. This will also update the DB"
  type        = bool
  default     = false
}

variable "auth_type" {
  description = "Select the authentication method for the RDS instance user. Options are `password` or `iam`"
  type        = string
  nullable    = false
  default     = "password"
  validation {
    condition     = can(regex("^(password|iam|secretsmanager)$",var.auth_type))
    error_message = "The RDS authentication method must be `password`, `iam` or `secretsmanager`"
  }
}

variable "tags" {
  description = "Tags to pass include on resources for this module"
  type        = map(any)
  default     = null
}
