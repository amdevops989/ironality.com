terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    kubectl = {
        source  = "gavinbunney/kubectl"
        version = "~> 1.14"
      }
 }
}

# Configure the AWS Provider
provider "aws" {
  region = var.region

  # Optional: Add default tags to all resources
  default_tags {
    tags = {
      Terraform   = "true"
      Environment = var.environment
      Project     = var.cluster_name
      ManagedBy   = "terraform"
    }
  }
}

data "aws_region" "current" {}

# Optional: Configure AWS provider for different region if needed
# provider "aws" {
#   alias  = "us_west_2"
#   region = "us-west-2"
# }

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", var.cluster_name, "--profile", var.profile]
  }

}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", var.cluster_name, "--profile", var.profile]
    }
  }

}
