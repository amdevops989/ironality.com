im using eks module latest version i want to add aws auth conf to allow one sso user to access full all resources and dev to read only

I'll help you configure AWS auth for your EKS cluster using the latest EKS module to allow SSO user full access and dev users read-only access.

Retrieving knowledge

Here's a complete configuration for your EKS cluster using the latest EKS module to add AWS auth configuration with SSO user full access and dev users read-only access:

1. EKS Module Configuration with AWS Auth
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "my-cluster"
  cluster_version = "1.28"

  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true

  # EKS Managed Node Groups
  eks_managed_node_groups = {
    main = {
      min_size     = 1
      max_size     = 3
      desired_size = 2

      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
    }
  }

  # AWS Auth configuration
  manage_aws_auth_configmap = true

  aws_auth_roles = [
    # SSO Admin Role - Full Access
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_AdministratorAccess_1234567890abcdef"
      username = "sso-admin-user"
      groups   = ["system:masters"]
    },
    # Dev Role - Read Only Access
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_DeveloperAccess_1234567890abcdef"
      username = "dev-user"
      groups   = ["dev-readonly"]
    }
  ]

  aws_auth_users = [
    # Example: Direct IAM user (if needed)
    {
      userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/admin-user"
      username = "admin-user"
      groups   = ["system:masters"]
    }
  ]

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

data "aws_caller_identity" "current" {}

2. Create RBAC Resources for Dev Read-Only Access
Create a separate file rbac.tf:

# ClusterRole for read-only access
resource "kubernetes_cluster_role" "dev_readonly" {
  depends_on = [module.eks]
  
  metadata {
    name = "dev-readonly"
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "services", "endpoints", "persistentvolumeclaims", "events", "configmaps", "secrets"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "daemonsets", "replicasets", "statefulsets"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["extensions"]
    resources  = ["deployments", "daemonsets", "replicasets", "ingresses"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["ingresses", "networkpolicies"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["batch"]
    resources  = ["jobs", "cronjobs"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["autoscaling"]
    resources  = ["horizontalpodautoscalers"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["policy"]
    resources  = ["poddisruptionbudgets"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["metrics.k8s.io"]
    resources  = ["pods", "nodes"]
    verbs      = ["get", "list"]
  }
}

# ClusterRoleBinding for dev-readonly group
resource "kubernetes_cluster_role_binding" "dev_readonly" {
  depends_on = [kubernetes_cluster_role.dev_readonly]
  
  metadata {
    name = "dev-readonly"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "dev-readonly"
  }

  subject {
    kind      = "Group"
    name      = "dev-readonly"
    api_group = "rbac.authorization.k8s.io"
  }
}

3. Alternative: Using Access Entries (Recommended for Latest EKS)
If you prefer using the newer Access Entries method instead of aws-auth ConfigMap:

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "my-cluster"
  cluster_version = "1.28"

  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true

  # Set authentication mode to use Access Entries
  authentication_mode = "API_AND_CONFIG_MAP"

  # Access entries for SSO users
  access_entries = {
    # SSO Admin - Full Access
    sso_admin = {
      kubernetes_groups = []
      principal_arn     = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_AdministratorAccess_1234567890abcdef"

      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }

    # SSO Dev - Read Only Access
    sso_dev = {
      kubernetes_groups = []
      principal_arn     = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_DeveloperAccess_1234567890abcdef"

      policy_associations = {
        readonly = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  # EKS Managed Node Groups
  eks_managed_node_groups = {
    main = {
      min_size     = 1
      max_size     = 3
      desired_size = 2

      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

4. Manual aws-auth ConfigMap (if not using Terraform module management)
If you need to manually apply the aws-auth ConfigMap:

apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: arn:aws:iam::ACCOUNT_ID:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_AdministratorAccess_1234567890abcdef
      username: sso-admin-user
      groups:
        - system:masters
    - rolearn: arn:aws:iam::ACCOUNT_ID:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_DeveloperAccess_1234567890abcdef
      username: dev-user
      groups:
        - dev-readonly
    - rolearn: arn:aws:iam::ACCOUNT_ID:role/NodeInstanceRole
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
  mapUsers: |
    - userarn: arn:aws:iam::ACCOUNT_ID:user/admin-user
      username: admin-user
      groups:
        - system:masters

5. How to Find Your SSO Role ARNs
To find your SSO role ARNs, use:

# List all roles with SSO in the name
aws iam list-roles --query 'Roles[?contains(RoleName, `AWSReservedSSO`)].{RoleName:RoleName,Arn:Arn}' --output table

# Or get specific role
aws iam get-role --role-name AWSReservedSSO_AdministratorAccess_1234567890abcdef

Run in CloudShell
6. Testing Access
After applying the configuration:

# Test SSO admin access
aws sso login --profile sso-admin
aws eks update-kubeconfig --region us-west-2 --name my-cluster --profile sso-admin
kubectl get pods --all-namespaces

# Test dev read-only access
aws sso login --profile sso-dev
aws eks update-kubeconfig --region us-west-2 --name my-cluster --profile sso-dev
kubectl get pods --all-namespaces
kubectl create deployment test --image=nginx  # This should fail for dev users

Run in CloudShell
Key Points:
Replace placeholders: Update ACCOUNT_ID and the SSO role suffixes with your actual values
SSO Role Format: SSO roles follow the pattern arn:aws:iam::ACCOUNT_ID:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_PERMISSION_SET_NAME_RANDOM_SUFFIX
Access Entries vs aws-auth: Access Entries is the newer, recommended approach for EKS authentication
RBAC: The dev-readonly ClusterRole provides comprehensive read-only access across most Kubernetes resources
Authentication Mode: Use API_AND_CONFIG_MAP to support both methods during migration
This configuration gives your SSO admin user full cluster access while restricting dev users to read-only permissions across all namespaces.

Sources
Identity and Access Management - Amazon EKS 

Configure SSO user access to Amazon EKS cluster | AWS re:Post 

Create and manage Amazon EKS clusters with Step Functions - AWS Step Functions 

AWS Batch on Amazon EKS job is stuck in RUNNABLE status - AWS Batch 

Grant IAM users and roles access to Kubernetes APIs - Amazon EKS 



