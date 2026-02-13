# resource "kubernetes_manifest" "karpenter_provisioner" {
#   manifest = {
#     apiVersion = "karpenter.sh/v1alpha5"
#     kind       = "Provisioner"
#     metadata = {
#       name = "default"
#     }
#     spec = {
#       cluster = var.cluster_name

#       # Limits for max resources
#       limits = {
#         resources = {
#           cpu = "1000"
#         }
#       }

#       # Use your private subnets
#       provider = {
#         subnetSelector = { "karpenter.sh/discovery" = var.cluster_name }
#         securityGroupSelector = { "karpenter.sh/discovery" = var.cluster_name }
#         instanceProfile = var.eks_node_role   # ✅ Node Group IAM role ARN
#       }

#       # Node requirements
#       requirements = [
#         { key = "node.kubernetes.io/instance-type", operator = "In", values = [var.karpenter_instance_types] },
#         { key = "karpenter.k8s.aws/capacity-type", operator = "In", values = [var.karpenter_capacity_types] }
#       ]

#       # TTL: remove empty nodes after X seconds
#       ttlSecondsAfterEmpty = var.karpenter_ttl_seconds_after_empty
#     }
#   }
# }
