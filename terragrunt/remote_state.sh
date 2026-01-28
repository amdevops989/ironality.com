aws s3 mb s3://travelersources-tfstate --region us-east-1 --profile devops-am


aws dynamodb create-table \
  --table-name travelersources-tf-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1 \
  --profile devops-am


## hashing password : 
# install if needed (Debian/Ubuntu)
sudo apt-get install -y apache2-utils
htpasswd -nbBC 10 admin 'admin1233' | cut -d: -f2  

## remove remote state

aws dynamodb delete-item \
  --table-name travelersources-tf-locks \
  --key '{"LockID":{"S":"942012ca-2a61-d7ee-b2aa-e5bfe91a0655"}}' \
  --profile devops-am \
  --region us-east-1


aws eks update-kubeconfig --name travelersources-dev --region us-east-1 --profile devops-am


## to unlock terr lock
terragrunt force-unlock 092da35b-cfef-8030-bc23-cf2a5422ba32

##     Why this happens

SSO user can create AWS resources, including EKS clusters, because it has AWS IAM permissions. ✅

Kubernetes API in EKS is separate — it uses RBAC, not IAM directly.

When you try to create a namespace or service account via Terraform, you’re authenticating to the Kubernetes API using a token.

If you passed the token from aws sts get-token (or dependency.eks.outputs.cluster_token), it’s not automatically mapped in the cluster RBAC.

Even though your SSO user is Administrator in AWS, it doesn’t automatically become a Kubernetes admin.

By default, only users/roles listed in the aws-auth ConfigMap in the EKS cluster can act as Kubernetes admins (system:masters group).


provider "kubernetes" {
  host                   = var.k8s_host
  cluster_ca_certificate = base64decode(var.k8s_ca)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", var.cluster_name, "--region", var.region]
  }
}


## new root.hcl ## dont forget dependencies ! 

locals {
  aws_region   = "us-east-1"
  aws_profile  = "devops-am"
  project_name = "travelersources"
}

# ------------------------------------------------------------
# 🧱 Terraform Required Providers
# ------------------------------------------------------------
generate "terraform_providers" {
  path      = "versions.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.10"
    }
  }

  backend "s3" {}
}
EOF
}

# ------------------------------------------------------------
# ☁️ AWS Provider Configuration
# ------------------------------------------------------------
generate "aws_provider" {
  path      = "provider-aws.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region  = "${local.aws_region}"
  profile = "${local.aws_profile}"
}
EOF
}

# ------------------------------------------------------------
# ☸️ Kubernetes & Helm Providers
# ------------------------------------------------------------
generate "k8s_providers" {
  path      = "provider-k8s.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
# -----------------------------
# Kubernetes Provider
# -----------------------------
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

# -----------------------------
# Helm Provider
# -----------------------------
provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}
EOF
}

# ------------------------------------------------------------
# 🔒 Remote Backend Configuration (S3 + DynamoDB)
# ------------------------------------------------------------
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

# ------------------------------------------------------------
# 🌍 Global Inputs for All Modules
# ------------------------------------------------------------
inputs = {
  project_name = local.project_name
  aws_region   = local.aws_region
  aws_profile  = local.aws_profile
}
