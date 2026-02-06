# # karpenter-nodepool.tf - Corrected with proper data types
# locals {
#   private_subnet_ids = aws_subnet.private[*].id
# }
# # karpenter-nodepool.tf - Removed restricted tags

# # karpenter-nodepool.tf - Removed restricted tags

# resource "kubectl_manifest" "karpenter_nodeclass" {
#   yaml_body = yamlencode({
#     apiVersion = "karpenter.k8s.aws/v1beta1"
#     kind       = "EC2NodeClass"
#     metadata = {
#       name = "${var.cluster_name}-spot-test"
#     }
#     spec = {
#       amiFamily = "AL2"
      
#       subnetSelectorTerms = [
#         {
#           tags = {
#             "karpenter.sh/discovery" = var.cluster_name
#           }
#         }
#       ]
      
#       securityGroupSelectorTerms = [
#         {
#           tags = {
#             "karpenter.sh/discovery" = var.cluster_name
#           }
#         }
#       ]
      
#       role = aws_iam_role.node_group.name
      
#       userData = base64encode(templatefile("${path.module}/karpenter-userdata.sh", {
#         cluster_name = var.cluster_name
#         endpoint     = aws_eks_cluster.main.endpoint
#         certificate_authority = aws_eks_cluster.main.certificate_authority[0].data
#       }))
      
#       blockDeviceMappings = [
#         {
#           deviceName = "/dev/xvda"
#           ebs = {
#             volumeSize = "20Gi"
#             volumeType = "gp3"
#             encrypted = true
#             deleteOnTermination = true
#           }
#         }
#       ]
      
#       # Removed restricted kubernetes.io/cluster tag
#       tags = {
#         Name = "${var.cluster_name}-karpenter-spot"
#         "karpenter.sh/discovery" = var.cluster_name
#         Environment = "test"
#         ManagedBy = "karpenter"
#       }
#     }
#   })

#   depends_on = [
#     helm_release.karpenter,
#     aws_iam_instance_profile.karpenter_node_instance_profile
#   ]
# }

# # NodePool configuration
# resource "kubectl_manifest" "karpenter_nodepool_spot_test" {
#   yaml_body = yamlencode({
#     apiVersion = "karpenter.sh/v1beta1"
#     kind       = "NodePool"
#     metadata = {
#       name = "${var.cluster_name}-spot-test"
#     }
#     spec = {
#       template = {
#         metadata = {
#           labels = {
#             "node-type" = "karpenter-spot-test"
#           }
#         }
#         spec = {
#           nodeClassRef = {
#             apiVersion = "karpenter.k8s.aws/v1beta1"
#             kind       = "EC2NodeClass"
#             name       = "${var.cluster_name}-spot-test"
#           }
          
#           requirements = [
#             {
#               key      = "karpenter.sh/capacity-type"
#               operator = "In"
#               values   = ["spot"]
#             },
#             {
#               key      = "node.kubernetes.io/instance-type"
#               operator = "In"
#               values   = ["t3.medium", "t3.small", "t2.medium"]
#             }
#           ]
          
#           nodeProperties = {
#             taints = [
#               {
#                 key    = "spot-instance"
#                 value  = "true"
#                 effect = "NoSchedule"
#               }
#             ]
#           }
#         }
#       }
      
#       disruption = {
#         consolidationPolicy = "WhenEmpty"
#         consolidateAfter    = "5s"
#         expireAfter         = "2m"
#       }
      
#       limits = {
#         cpu    = "10"
#         memory = "20Gi"
#       }
#     }
#   })

#   depends_on = [
#     kubectl_manifest.karpenter_nodeclass
#   ]
# }

