# karpenter.tf





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
