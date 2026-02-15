locals {
  # Detect env folder name (dev or DR)
  env = basename(dirname(get_terragrunt_dir()))

  # Load env-specific config
  env_config = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  aws_region   = local.env_config.locals.aws_region
  aws_profile  = local.env_config.locals.aws_profile
  project_name = local.env_config.locals.project_name
}

inputs = {
  aws_region   = local.aws_region
  aws_profile  = local.aws_profile
  project_name = local.project_name
}

# ===============================
# AWS Provider
# ===============================
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region  = "${local.aws_region}"
  profile = "${local.aws_profile}"
}
EOF
}

# ===============================
# Remote State (PER ENV)
# ===============================
generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  backend "s3" {
    bucket         = "${local.project_name}-tfstate-${local.env}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "${local.aws_region}"
    dynamodb_table = "${local.project_name}-tf-locks-${local.env}"
    encrypt        = true
  }
}
EOF
}
