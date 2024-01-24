locals {
  name            = var.name

  resourcenames_suffix = var.resourcenames_suffix != "" ? var.resourcenames_suffix : "${random_id.resourcenames_suffix.hex}"
}
