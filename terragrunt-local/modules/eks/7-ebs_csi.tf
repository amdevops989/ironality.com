# locals {
#   oidc_provider = replace(
#     aws_iam_openid_connect_provider.oidc.url,
#     "https://",
#     ""
#   )
# }

# resource "aws_iam_role" "ebs_csi_role" {
#   name = "${var.cluster_name}-ebs-csi-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Principal = {
#           Federated = aws_iam_openid_connect_provider.oidc.arn
#         }
#         Action = "sts:AssumeRoleWithWebIdentity"
#         Condition = {
#           StringEquals = {
#             "${local.oidc_provider}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
#             "${local.oidc_provider}:aud" = "sts.amazonaws.com"
#           }
#         }
#       }
#     ]
#   })
#   tags = {
#     TerraformManaged = "true"
#   }
# }

# resource "aws_iam_policy" "ebs_csi_kms" {
#   name = "${var.cluster_name}-ebs-csi-kms"

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "kms:CreateGrant", # Required for PVC attach without AccessDenied
#           "kms:ListGrants",
#           "kms:RevokeGrant"
#         ]
#         Resource = var.kms_key_arn
#         Condition = {
#           Bool = {
#             "aws:PrincipalTag/TerraformManaged" = "true"
#           }
#         }
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           "kms:Encrypt",
#           "kms:Decrypt",
#           "kms:ReEncrypt*",
#           "kms:GenerateDataKey*",
#           "kms:DescribeKey"
#         ]
#         Resource = var.kms_key_arn
#       }
#     ]
#   })
# }



# resource "aws_iam_role_policy_attachment" "ebs_csi_kms_attach" {
#   role       = aws_iam_role.ebs_csi_role.name
#   policy_arn = aws_iam_policy.ebs_csi_kms.arn
# }
# # resource "kubernetes_service_account" "ebs_csi" {
# #   metadata {
# #     name      = "ebs-csi-controller-sa"
# #     namespace = "kube-system"
# #     annotations = {
# #       "eks.amazonaws.com/role-arn" = aws_iam_role.ebs_csi_role.arn
# #     }
# #   }
# # }

# resource "aws_eks_addon" "csi_driver" {
#   cluster_name             = var.cluster_name
#   addon_name               = "aws-ebs-csi-driver"
#   addon_version            = "v1.55.0-eksbuild.1"
#   service_account_role_arn = aws_iam_role.ebs_csi_role.arn
#   # depends_on = [
#   #    kubernetes_service_account.ebs_csi
#   # ]
# }




# # resource "kubernetes_storage_class_v1" "encrypted_gp3" {
# #   metadata {
# #     name = "encrypted-gp3"
# #   }

# #   storage_provisioner = "ebs.csi.aws.com"

# #   parameters = {
# #     type      = "gp3"
# #     encrypted = "true"
# #     kmsKeyId  = var.kms_key_arn
# #   }

# #   reclaim_policy      = "Delete"
# #   volume_binding_mode = "WaitForFirstConsumer"
# # }
