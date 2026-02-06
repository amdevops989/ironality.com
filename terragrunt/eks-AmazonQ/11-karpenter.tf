# karpenter.tf

# Instance profile using existing node group role
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




# # Get current data
# data "aws_caller_identity" "current" {}
# data "aws_region" "current" {}

# # Minimal SQS Queue for testing
# resource "aws_sqs_queue" "karpenter_interruption" {
#   name                      = "${var.cluster_name}-karpenter-interruption"
#   message_retention_seconds = 300
#   sqs_managed_sse_enabled   = true

#   tags = {
#     Name = "${var.cluster_name}-karpenter-interruption"
#   }
# }


# # Simple SQS Queue Policy
# resource "aws_sqs_queue_policy" "karpenter_interruption" {
#   queue_url = aws_sqs_queue.karpenter_interruption.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Principal = {
#           Service = "events.amazonaws.com"
#         }
#         Action   = "sqs:SendMessage"
#         Resource = aws_sqs_queue.karpenter_interruption.arn
#       },
#       {
#         Effect = "Allow"
#         Principal = {
#           AWS = aws_iam_role.karpenter_controller.arn
#         }
#         Action = [
#           "sqs:ReceiveMessage",
#           "sqs:DeleteMessage",
#           "sqs:GetQueueAttributes"
#         ]
#         Resource = aws_sqs_queue.karpenter_interruption.arn
#       }
#     ]
#   })
# }


# # Only spot interruption rule for cost testing
# resource "aws_cloudwatch_event_rule" "karpenter_spot_interruption" {
#   name = "${var.cluster_name}-karpenter-spot-interruption"

#   event_pattern = jsonencode({
#     source      = ["aws.ec2"]
#     detail-type = ["EC2 Spot Instance Interruption Warning"]
#   })

#   tags = {
#     Name = "${var.cluster_name}-karpenter-spot-interruption"
#   }
# }

# resource "aws_cloudwatch_event_target" "karpenter_spot_interruption" {
#   rule      = aws_cloudwatch_event_rule.karpenter_spot_interruption.name
#   target_id = "KarpenterSpotTarget"
#   arn       = aws_sqs_queue.karpenter_interruption.arn
# }



# Karpenter Helm Release WITHOUT interruption queue
# karpenter.tf - Minimal configuration without anti-affinity

resource "helm_release" "karpenter" {
  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  namespace  = "karpenter"
  version    = "0.37.0"

  create_namespace = true

  values = [
    yamlencode({
      serviceAccount = {
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.karpenter_controller.arn
        }
      }
      settings = {
        clusterName     = aws_eks_cluster.main.name
        clusterEndpoint = aws_eks_cluster.main.endpoint
      }
      
      # Force single replica
      replicas = 1
      
      resources = {
        requests = {
          cpu    = "50m"
          memory = "128Mi"
        }
        limits = {
          cpu    = "200m"
          memory = "256Mi"
        }
      }
      
      # Minimal affinity - only avoid Karpenter-managed nodes
      affinity = {
        nodeAffinity = {
          requiredDuringSchedulingIgnoredDuringExecution = {
            nodeSelectorTerms = [
              {
                matchExpressions = [
                  {
                    key      = "karpenter.sh/nodepool"
                    operator = "DoesNotExist"
                  }
                ]
              }
            ]
          }
        }
        # Completely remove podAntiAffinity
      }
      
      # Disable pod disruption budget
      podDisruptionBudget = {
        enabled = false
      }
      
      # Disable leader election for single replica
      controller = {
        env = [
          {
            name  = "LEADER_ELECT"
            value = "false"
          }
        ]
      }
    })
  ]

  depends_on = [
    aws_eks_node_group.main,
    aws_iam_role.karpenter_controller
  ]
}
