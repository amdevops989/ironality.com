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
  backend "s3" {
    
  }
}
# -----------------------------
# Get current AWS account ID
# -----------------------------
data "aws_caller_identity" "current" {}



# -----------------------------
# IAM Roles
# -----------------------------
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.cluster_name}-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSVPCResourceController" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

# -----------------------------
# EKS Cluster
# -----------------------------
resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.30"

  vpc_config {
    subnet_ids = var.private_subnets
  }

  encryption_config {
    resources = ["secrets"]
    provider {
      key_arn = var.kms_key_id
    }
  }

  tags = var.tags
}

# -----------------------------
# EKS Node Group IAM Role
# -----------------------------
resource "aws_iam_role" "eks_node_role" {
  name = "${var.cluster_name}-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# -----------------------------
# Managed Node Group
# -----------------------------
resource "aws_eks_node_group" "default" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-ng"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = var.private_subnets
  ami_type        = "AL2_x86_64"
  instance_types  = [var.node_instance_type]
  disk_size       = 20
  capacity_type   = "SPOT"

  scaling_config {
    desired_size = var.node_desired_capacity
    min_size     = var.node_min_capacity
    max_size     = var.node_max_capacity
  }

  update_config {
    max_unavailable = 1
  }

  tags = merge(var.tags, {
    "Name" = "${var.cluster_name}-node"
  })
}

# -----------------------------
# OIDC Provider
# -----------------------------
data "aws_eks_cluster" "cluster" {
  name = aws_eks_cluster.this.name
}

data "aws_eks_cluster_auth" "cluster" {
  name = aws_eks_cluster.this.name
}

data "tls_certificate" "oidc" {
  url = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "oidc" {
  url = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.oidc.certificates[0].sha1_fingerprint]
}

# -----------------------------
# Kubernetes Provider
# -----------------------------
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}


provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

# # -----------------------------
# # aws-auth ConfigMap (mapRoles only, SSO/OIDC ready)
# # -----------------------------
# locals {
#   node_role_map = [
#     {
#       rolearn  = aws_iam_role.eks_node_role.arn
#       username = "system:node:{{EC2PrivateDNSName}}"
#       groups   = ["system:bootstrappers", "system:nodes"]
#     }
#   ]

#   admin_role_map_roles = [
#     for role in var.admin_roles : {
#       rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${role}"
#       username = "${role}/SeniorDevops-am"
#       groups   = ["system:masters"]
#     }
#   ]

#   developer_role_map_roles = [
#     for role in var.developer_roles : {
#       rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${role}"
#       username = role
#       groups   = ["${var.env}-developers"]
#     }
#   ]

#   map_roles = concat(
#     local.node_role_map,
#     local.admin_role_map_roles,
#     local.developer_role_map_roles
#   )
# }

# resource "kubernetes_config_map" "aws_auth" {
#   metadata {
#     name      = "aws-auth"
#     namespace = "kube-system"
#   }

#   data = {
#     mapRoles = yamlencode(local.map_roles)
#   }

#   depends_on = [
#     aws_eks_cluster.this,
#     aws_iam_role.eks_node_role
#   ]
# }

# data "aws_caller_identity" "current" {}

# -----------------------------
# aws-auth ConfigMap
# -----------------------------
locals {
  # Node mapping
  node_role_map = [
    {
      rolearn  = aws_iam_role.eks_node_role.arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups   = ["system:bootstrappers", "system:nodes"]
    }
  ]

# Admin SSO roles mapping
  admin_role_map = [
    for role in var.admin_roles : {
      rolearn  = role
      username = "admin_user"
      groups   = ["system:masters"]
    }
  ]

  # Developer SSO roles
  developer_role_map = [
    for role in var.developer_roles : {
      rolearn  = role
      username = "{{SessionName}}"
      groups   = ["${var.env}-developers"]
    }
  ]

  map_roles = concat(local.node_role_map, local.admin_role_map, local.developer_role_map)
}

resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode(local.map_roles)
  }

  depends_on = [
    aws_eks_cluster.this,
    aws_iam_role.eks_node_role
  ]
}


# -----------------------------
# AWS EBS CSI Driver (Helm)
# -----------------------------
resource "helm_release" "ebs_csi" {
  name       = "aws-ebs-csi-driver"
  repository = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver"
  chart      = "aws-ebs-csi-driver"
  namespace  = "kube-system"
  version    = "2.22.0"

  set {
    name  = "controller.serviceAccount.create"
    value = "true"
  }
  set {
    name  = "controller.serviceAccount.name"
    value = "ebs-csi-controller-sa"
  }
}

# -----------------------------
# Encrypted gp3 StorageClass
# -----------------------------
resource "kubernetes_storage_class_v1" "encrypted_gp3" {
  metadata {
    name = "encrypted-gp3"
  }

  storage_provisioner = "ebs.csi.aws.com"

  parameters = {
    type     = "gp3"
    encrypted = "true"
    kmsKeyId  = var.kms_key_id
  }

  reclaim_policy      = "Retain"
  volume_binding_mode = "WaitForFirstConsumer"
}
