locals {
  aws_region   = "us-east-1"
  aws_profile  = "devops-am"
  project_name = "travelersources"
}

# === AWS Provider ===
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



# === Remote Backend (S3 + DynamoDB) ===
remote_state {
  backend = "s3"

  config = {
    bucket         = "${local.project_name}-tfstate"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.aws_region
    profile        = local.aws_profile
    dynamodb_table = "${local.project_name}-tf-locks"
    encrypt        = true
  }
}

# === Global Inputs for all modules ===
inputs = {
  project_name = local.project_name
  aws_region   = local.aws_region
  aws_profile  = local.aws_profile
}
