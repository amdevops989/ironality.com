# # KMS Key for EBS encryption
# resource "aws_kms_key" "eks_ebs" {
#   description             = "EKS EBS encryption key"
#   deletion_window_in_days = 7
#   enable_key_rotation     = true

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Id      = "eks-ebs-key-policy"
#     Statement = [
#       {
#         Sid    = "Enable IAM User Permissions"
#         Effect = "Allow"
#         Principal = {
#           AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
#         }
#         Action   = "kms:*"
#         Resource = "*"
#       },
#       {
#         Sid    = "Allow EKS Node Instance Role"
#         Effect = "Allow"
#         Principal = {
#           AWS = aws_iam_role.node_group.arn
#         }
#         Action = [
#           "kms:Encrypt",
#           "kms:Decrypt",
#           "kms:ReEncrypt*",
#           "kms:GenerateDataKey*",
#           "kms:DescribeKey"
#         ]
#         Resource = "*"
#         Condition = {
#           StringEquals = {
#             "kms:ViaService" = "ec2.${var.region}.amazonaws.com"
#           }
#         }
#       },
#       {
#         Sid    = "Allow EKS Node Instance Role Grant Operations"
#         Effect = "Allow"
#         Principal = {
#           AWS = aws_iam_role.node_group.arn
#         }
#         Action = [
#           "kms:CreateGrant",
#           "kms:ListGrants",
#           "kms:RevokeGrant"
#         ]
#         Resource = "*"
#         Condition = {
#           Bool = {
#             "kms:GrantIsForAWSResource" = "true"
#           }
#           StringEquals = {
#             "kms:ViaService" = "ec2.${var.region}.amazonaws.com"
#           }
#         }
#       },
#       {
#         Sid    = "Allow Auto Scaling Service Linked Role"
#         Effect = "Allow"
#         Principal = {
#           AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
#         }
#         Action = [
#           "kms:Encrypt",
#           "kms:Decrypt",
#           "kms:ReEncrypt*",
#           "kms:GenerateDataKey*",
#           "kms:DescribeKey"
#         ]
#         Resource = "*"
#       },
#       {
#         Sid    = "Allow Auto Scaling Service Linked Role Grant Operations"
#         Effect = "Allow"
#         Principal = {
#           AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
#         }
#         Action   = "kms:CreateGrant"
#         Resource = "*"
#         Condition = {
#           Bool = {
#             "kms:GrantIsForAWSResource" = "true"
#           }
#         }
#       },
#       {
#         Sid    = "Allow EC2 Service"
#         Effect = "Allow"
#         Principal = {
#           Service = "ec2.amazonaws.com"
#         }
#         Action = [
#           "kms:Encrypt",
#           "kms:Decrypt",
#           "kms:ReEncrypt*",
#           "kms:GenerateDataKey*",
#           "kms:DescribeKey"
#         ]
#         Resource = "*"
#       }
#     ]
#   })

#   tags = {
#     Name = "${var.cluster_name}-ebs-encryption-key"
#   }
# }


# resource "aws_kms_alias" "eks_ebs" {
#   name          = "alias/${var.cluster_name}-ebs-encryption"
#   target_key_id = aws_kms_key.eks_ebs.key_id
# }
