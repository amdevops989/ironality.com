# IAM Roles

###############
## EKS Role ####
################

resource "aws_iam_role" "cluster" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}



resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}
####################
### NodeGroup Role
####################
resource "aws_iam_role" "node_group" {
  name = "${var.cluster_name}-node-group-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "node_group_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_group_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_group_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_group.name
}

# Additional IAM policy for KMS access
resource "aws_iam_role_policy" "node_group_kms" {
  name = "${var.cluster_name}-node-group-kms-policy"
  role = aws_iam_role.node_group.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = [var.kms_key_arn]
        Condition = {
          StringEquals = {
            "kms:ViaService" = "ec2.${var.region}.amazonaws.com"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "kms:CreateGrant",
          "kms:ListGrants",
          "kms:RevokeGrant"
        ]
        Resource = [var.kms_key_arn]
        Condition = {
          Bool = {
            "kms:GrantIsForAWSResource" = "true"
          }
          StringEquals = {
            "kms:ViaService" = "ec2.${var.region}.amazonaws.com"
          }
        }
      }
    ]
  })
}


#############################
# IAM Role for EBS CSI Driver
#############################

resource "aws_iam_role" "ebs_csi_driver" {
  name = "${var.cluster_name}-ebs-csi-driver-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        }
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name = "${var.cluster_name}-ebs-csi-driver-role"
  }
}

# Attach AWS managed policy for EBS CSI Driver
resource "aws_iam_role_policy_attachment" "ebs_csi_driver_policy" {
  role       = aws_iam_role.ebs_csi_driver.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# Custom policy for KMS permissions
resource "aws_iam_role_policy" "ebs_csi_kms_policy" {
  name = "${var.cluster_name}-ebs-csi-kms-policy"
  role = aws_iam_role.ebs_csi_driver.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowUseOfKmsKey"
        Effect = "Allow"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = var.kms_key_arn
        Condition = {
          StringEquals = {
            "kms:ViaService" = "ec2.${data.aws_region.current.name}.amazonaws.com"
          }
        }
      },
      {
        Sid    = "AllowGrantForEBS"
        Effect = "Allow"
        Action = [
          "kms:CreateGrant"
        ]
        Resource = var.kms_key_arn
        Condition = {
          Bool = {
            "kms:GrantIsForAWSResource" = "true"
          }
          StringEquals = {
            "kms:ViaService" = "ec2.${data.aws_region.current.name}.amazonaws.com"
          }
        }
      }
    ]
  })
}


############################
## Karpenter "s Role#######
###########################

resource "aws_iam_instance_profile" "karpenter_node_instance_profile" {
  name = "${var.cluster_name}-karpenter-node-instance-profile"
  role = aws_iam_role.node_group.name  # Reusing your existing node group role

  tags = {
    Name = "${var.cluster_name}-karpenter-node-instance-profile"
  }
}

# Add KMS permissions to existing node group role for Karpenter nodes
resource "aws_iam_role_policy" "node_group_kms_policy_karpenter" {
  name = "${var.cluster_name}-node-group-kms-policy-karpenter"
  role = aws_iam_role.node_group.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:GenerateDataKey*",
          "kms:ReEncrypt*"
        ]
        Resource = [
          var.kms_key_arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:CreateGrant"
        ]
        Resource = [
          var.kms_key_arn
        ]
        Condition = {
          Bool = {
            "kms:GrantIsForAWSResource" = "true"
          }
          StringEquals = {
            "kms:ViaService" = "ec2.${data.aws_region.current.name}.amazonaws.com"
          }
        }
      }
    ]
  })
}

# Karpenter Controller IAM Role
resource "aws_iam_role" "karpenter_controller" {
  name = "${var.cluster_name}-karpenter-controller"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        }
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:karpenter:karpenter"
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name = "${var.cluster_name}-karpenter-controller"
  }
}

# Updated Karpenter Controller Policy with SQS permissions
# Simplified Karpenter Controller Policy (without SQS)
# karpenter.tf - Enhanced IAM policy with all required permissions

resource "aws_iam_role_policy" "karpenter_controller" {
  name = "${var.cluster_name}-karpenter-controller-policy"
  role = aws_iam_role.karpenter_controller.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEC2DescribeActions"
        Effect = "Allow"
        Action = [
          "ec2:DescribeImages",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DescribeInstanceAttribute",
          "ec2:DescribeRegions",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:DescribeSpotPriceHistory",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeVpcs"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowEC2RunInstances"
        Effect = "Allow"
        Action = [
          "ec2:RunInstances",
          "ec2:CreateFleet"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowEC2TerminateInstances"
        Effect = "Allow"
        Action = [
          "ec2:TerminateInstances"
        ]
        Resource = "*"
        Condition = {
          StringLike = {
            "ec2:ResourceTag/karpenter.sh/nodepool" = "*"
          }
        }
      },
      {
        Sid    = "AllowEC2LaunchTemplateActions"
        Effect = "Allow"
        Action = [
          "ec2:CreateLaunchTemplate",
          "ec2:CreateLaunchTemplateVersion",
          "ec2:DeleteLaunchTemplate",
          "ec2:DeleteLaunchTemplateVersions"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowEC2TagActions"
        Effect = "Allow"
        Action = [
          "ec2:CreateTags",
          "ec2:DeleteTags"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowSSMGetParameter"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = [
          "arn:aws:ssm:*:*:parameter/aws/service/*"
        ]
      },
      {
        Sid    = "AllowPricingGetProducts"
        Effect = "Allow"
        Action = [
          "pricing:GetProducts"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowPassRole"
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = aws_iam_role.node_group.arn
      },
      {
        Sid    = "AllowCreateServiceLinkedRole"
        Effect = "Allow"
        Action = [
          "iam:CreateServiceLinkedRole"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "iam:AWSServiceName" = [
              "spot.amazonaws.com",
              "spotfleet.amazonaws.com"
            ]
          }
        }
      }
    ]
  })
}
