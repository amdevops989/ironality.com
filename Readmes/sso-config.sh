curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install


####  Add to your terragrunt.hcl

At the top of your infra/live/terragrunt.hcl:

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region  = "eu-west-1"
  profile = "dev-sso"
}
EOF
}

## ⚙️ 2️⃣ Make It Default (Optional)

If you want to use devops-am without always typing --profile, you can export it:

export AWS_PROFILE=devops-am
export AWS_REGION=us-east-1


Add this to your shell config (~/.bashrc or ~/.zshrc) for persistence:

# AWS defaults
export AWS_PROFILE=devops-am
export AWS_REGION=us-east-1


Reload:

source ~/.bashrc


Now all aws, terraform, and terragrunt commands will default to that profile and region.

🧱 3️⃣ Configure Terragrunt to Use That Profile

In your root terragrunt.hcl (e.g., infra/live/terragrunt.hcl), generate the provider automatically 👇

locals {
  aws_region = "us-east-1"
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region  = "${local.aws_region}"
  profile = "devops-am"
}
EOF
}


This ensures every environment (dev, stg, prod) automatically uses your devops-am profile unless overridden.