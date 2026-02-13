# # -------------------------------------
# # Instance Profile for Karpenter Nodes
# # (reuses existing eks_node_role)
# # -------------------------------------
# resource "aws_iam_instance_profile" "karpenter_node_profile" {
#   name = "${var.cluster_name}-karpenter-node-profile"
#   role = aws_iam_role.eks_node_role.name
# }

# # -------------------------------------
# # Karpenter Controller IAM Role
# # -------------------------------------
# resource "aws_iam_role" "karpenter_controller" {
#   name = "${var.cluster_name}-karpenter-controller"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Effect = "Allow"
#       Principal = {
#         Federated = aws_iam_openid_connect_provider.oidc.arn
#       }
#       Action = "sts:AssumeRoleWithWebIdentity"
#       Condition = {
#         StringEquals = {
#           "${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:sub" =
#           "system:serviceaccount:karpenter:karpenter"
#         }
#       }
#     }]
#   })
#     tags = {
#         TerraformManaged = "true"
#     }
# }


# resource "aws_iam_policy" "karpenter_controller" {
#   name = "${var.cluster_name}-karpenter-controller"

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "ec2:RunInstances",
#           "ec2:CreateFleet",
#           "ec2:CreateLaunchTemplate",
#           "ec2:DeleteLaunchTemplate",
#           "ec2:Describe*",
#           "ec2:TerminateInstances",
#           "iam:PassRole",
#           "pricing:GetProducts",
#           "ssm:GetParameter"
#         ]
#         Resource = "*"
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "karpenter_controller_attach" {
#   role       = aws_iam_role.karpenter_controller.name
#   policy_arn = aws_iam_policy.karpenter_controller.arn
# }

# resource "helm_release" "karpenter" {
#   name       = "karpenter"
#   namespace  = "karpenter"
#   repository = "oci://public.ecr.aws/karpenter/karpenter"
#   chart      = "karpenter"
#   version    = "0.37.0"

#   create_namespace = true

#   set {
#     name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
#     value = aws_iam_role.karpenter_controller.arn
#   }

#   set {
#     name  = "settings.clusterName"
#     value = var.cluster_name
#   }

#   set {
#     name  = "settings.clusterEndpoint"
#     value = data.aws_eks_cluster.cluster.endpoint
#   }

#   set {
#     name  = "settings.defaultInstanceProfile"
#     value = aws_iam_instance_profile.karpenter_node_profile.name
#   }

#   depends_on = [
#     aws_iam_role_policy_attachment.karpenter_controller_attach
#   ]
# }


