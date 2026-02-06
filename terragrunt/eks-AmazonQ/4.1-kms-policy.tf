resource "aws_kms_key_policy" "existing_key_complete_policy" {
  key_id = var.kms_key_arn
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "eks-ebs-encryption-policy-complete"
    Statement = [
      # Root account access (required)
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      
      # EKS Cluster Service Role
      {
        Sid    = "Allow EKS Cluster Service Role"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.cluster_name}-cluster-service-role"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      
      # EKS Node Group Service Role
      {
        Sid    = "Allow EKS Node Group Service Role"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.cluster_name}-nodegroup-role"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      
      # EBS CSI Driver Service Account
      {
        Sid    = "Allow EBS CSI Driver Service Account"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.cluster_name}-ebs-csi-driver-role"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "ec2.${var.region}.amazonaws.com"
          }
        }
      },
      
      # Karpenter Node Role
      {
        Sid    = "Allow Karpenter Node Role"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.cluster_name}-karpenter-node-role"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      
      # Karpenter Controller Role
      {
        Sid    = "Allow Karpenter Controller Role"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.cluster_name}-karpenter-controller-role"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      
      # Auto Scaling Service-Linked Role (for Karpenter)
      {
        Sid    = "Allow Auto Scaling Service Linked Role"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "ec2.${var.region}.amazonaws.com"
          }
        }
      },
      
      # EC2 Service for EBS encryption operations
      {
        Sid    = "Allow EC2 Service for EBS Encryption Operations"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:CallerAccount" = data.aws_caller_identity.current.account_id
            "kms:ViaService"    = "ec2.${var.region}.amazonaws.com"
          }
          "ForAnyValue:StringEquals" = {
            "kms:EncryptionContextKeys" = "aws:ebs:id"
          }
        }
      },
      
      # EC2 Service for key description
      {
        Sid    = "Allow EC2 Service for Key Description"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action   = "kms:DescribeKey"
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:CallerAccount" = data.aws_caller_identity.current.account_id
            "kms:ViaService"    = "ec2.${var.region}.amazonaws.com"
          }
        }
      },
      
      # EKS Service for secrets encryption
      {
        Sid    = "Allow EKS Service for Secrets Encryption"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:CallerAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      
      # Grant creation for EBS operations
      {
        Sid    = "Allow Grant Creation for EBS Operations"
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.cluster_name}-ebs-csi-driver-role",
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.cluster_name}-karpenter-node-role",
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.cluster_name}-karpenter-controller-role",
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
          ]
        }
        Action = "kms:CreateGrant"
        Resource = "*"
        Condition = {
          Bool = {
            "kms:GrantIsForAWSResource" = "true"
          }
          StringEquals = {
            "kms:ViaService" = "ec2.${var.region}.amazonaws.com"
          }
          "ForAnyValue:StringEquals" = {
            "kms:EncryptionContextKeys" = "aws:ebs:id"
          }
        }
      },
      
      # Grant management for EBS operations
      {
        Sid    = "Allow Grant Management for EBS Operations"
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.cluster_name}-ebs-csi-driver-role",
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.cluster_name}-karpenter-node-role",
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.cluster_name}-karpenter-controller-role",
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
          ]
        }
        Action = [
          "kms:ListGrants",
          "kms:RevokeGrant"
        ]
        Resource = "*"
        Condition = {
          Bool = {
            "kms:GrantIsForAWSResource" = "true"
          }
          StringEquals = {
            "kms:ViaService" = "ec2.${var.region}.amazonaws.com"
          }
        }
      },
      
      # Grant creation for EKS cluster
      {
        Sid    = "Allow Grant Creation for EKS Cluster"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.cluster_name}-cluster-service-role"
        }
        Action = [
          "kms:CreateGrant",
          "kms:ListGrants",
          "kms:RevokeGrant"
        ]
        Resource = "*"
        Condition = {
          Bool = {
            "kms:GrantIsForAWSResource" = "true"
          }
        }
      }
    ]
  })
#  Critical: Wait for all IAM roles to be created before updating the policy
  depends_on = [
    aws_iam_role.cluster,
    aws_iam_role.node_group,
    aws_iam_role.ebs_csi_driver,
    aws_iam_role.karpenter
  ]
}
