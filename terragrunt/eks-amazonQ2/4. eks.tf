# EKS Cluster with AWS managed KMS encryption
module "eks" {
  source = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.kubernetes_version

  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true

  # AWS managed KMS encryption for secrets
  cluster_encryption_config = {
    resources        = ["secrets"]
    # Don't specify provider_key_arn to use AWS managed key
  }

  # Cluster access entry
  # To add the current caller identity as an administrator
  enable_cluster_creator_admin_permissions = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    # EBS CSI Driver addon
    aws-ebs-csi-driver = {
      most_recent = true
      service_account_role_arn = module.ebs_csi_irsa_role.iam_role_arn
    }
  }

  # Cost-effective managed node group
  eks_managed_node_groups = {
    main = {
      name = "main-nodegroup"
      ami_type = "AL2023_x86_64_STANDARD"
      instance_types = ["t3.small"]
      capacity_type  = "ON_DEMAND"
      
      min_size     = 1
      max_size     = 3
      desired_size = 1

      # Use AWS managed KMS for EBS encryption
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 20
            volume_type          = "gp3"
            iops                 = 3000
            throughput           = 150
            encrypted            = true
            # Don't specify kms_key_id to use AWS managed key
            delete_on_termination = true
          }
        }
      }

      # Labels for workload placement
      labels = {
        Environment = var.environment
        NodeGroup   = "main"
      }

      taints = {
        dedicated = {
          key    = "CriticalAddonsOnly"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      }

      tags = {
        Name = "${var.cluster_name}-main-nodegroup"
      }
    }
  }

  tags = var.tags
}

# EBS CSI Driver IRSA
module "ebs_csi_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name             = "${var.cluster_name}-ebs-csi-driver-role"
  attach_ebs_csi_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = var.tags
}
