# # karpenter.tf

# # Karpenter Node Pool IAM Role
# resource "aws_iam_role" "karpenter_node_instance_profile" {
#   name = "${var.cluster_name}-karpenter-node-instance-profile"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Principal = {
#           Service = "ec2.amazonaws.com"
#         }
#       }
#     ]
#   })

#   tags = {
#     Name = "${var.cluster_name}-karpenter-node-instance-profile"
#   }
# }

# # Attach required policies to Karpenter node role
# resource "aws_iam_role_policy_attachment" "karpenter_node_instance_profile_worker_node_policy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
#   role       = aws_iam_role.karpenter_node_instance_profile.name
# }

# resource "aws_iam_role_policy_attachment" "karpenter_node_instance_profile_cni_policy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
#   role       = aws_iam_role.karpenter_node_instance_profile.name
# }

# resource "aws_iam_role_policy_attachment" "karpenter_node_instance_profile_container_registry_policy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
#   role       = aws_iam_role.karpenter_node_instance_profile.name
# }

# resource "aws_iam_role_policy_attachment" "karpenter_node_instance_profile_ssm_policy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
#   role       = aws_iam_role.karpenter_node_instance_profile.name
# }

# # KMS permissions for Karpenter nodes
# resource "aws_iam_role_policy" "karpenter_node_kms_policy" {
#   name = "${var.cluster_name}-karpenter-node-kms-policy"
#   role = aws_iam_role.karpenter_node_instance_profile.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "kms:Decrypt",
#           "kms:DescribeKey",
#           "kms:Encrypt",
#           "kms:GenerateDataKey*",
#           "kms:ReEncrypt*"
#         ]
#         Resource = [
#           var.kms_key_arn
#         ]
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           "kms:CreateGrant"
#         ]
#         Resource = [
#           var.kms_key_arn
#         ]
#         Condition = {
#           Bool = {
#             "kms:GrantIsForAWSResource" = "true"
#           }
#           StringEquals = {
#             "kms:ViaService" = "ec2.${data.aws_region.current.name}.amazonaws.com"
#           }
#         }
#       }
#     ]
#   })
# }

# # Instance profile for Karpenter nodes
# resource "aws_iam_instance_profile" "karpenter_node_instance_profile" {
#   name = "${var.cluster_name}-karpenter-node-instance-profile"
#   role = aws_iam_role.karpenter_node_instance_profile.name

#   tags = {
#     Name = "${var.cluster_name}-karpenter-node-instance-profile"
#   }
# }

# # Karpenter Controller IAM Role
# resource "aws_iam_role" "karpenter_controller" {
#   name = "${var.cluster_name}-karpenter-controller"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRoleWithWebIdentity"
#         Effect = "Allow"
#         Principal = {
#           Federated = aws_iam_openid_connect_provider.eks.arn
#         }
#         Condition = {
#           StringEquals = {
#             "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:karpenter:karpenter"
#             "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud" = "sts.amazonaws.com"
#           }
#         }
#       }
#     ]
#   })

#   tags = {
#     Name = "${var.cluster_name}-karpenter-controller"
#   }
# }

# # Karpenter Controller Policy
# resource "aws_iam_role_policy" "karpenter_controller" {
#   name = "${var.cluster_name}-karpenter-controller-policy"
#   role = aws_iam_role.karpenter_controller.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "ssm:GetParameter",
#           "iam:PassRole",
#           "ec2:DescribeImages",
#           "ec2:RunInstances",
#           "ec2:DescribeSubnets",
#           "ec2:DescribeSecurityGroups",
#           "ec2:DescribeLaunchTemplates",
#           "ec2:DescribeInstances",
#           "ec2:DescribeInstanceTypes",
#           "ec2:DescribeInstanceTypeOfferings",
#           "ec2:DescribeAvailabilityZones",
#           "ec2:DeleteLaunchTemplate",
#           "ec2:CreateTags",
#           "ec2:CreateLaunchTemplate",
#           "ec2:CreateFleet",
#           "ec2:DescribeSpotPriceHistory",
#           "pricing:GetProducts"
#         ]
#         Resource = "*"
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           "ec2:TerminateInstances"
#         ]
#         Resource = "*"
#         Condition = {
#           StringLike = {
#             "ec2:ResourceTag/karpenter.sh/nodepool" = "*"
#           }
#         }
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           "iam:PassRole"
#         ]
#         Resource = aws_iam_role.karpenter_node_instance_profile.arn
#       }
#     ]
#   })
# }

# # SQS Queue for Karpenter interruption handling
# resource "aws_sqs_queue" "karpenter_interruption" {
#   name                      = "${var.cluster_name}-karpenter-interruption"
#   message_retention_seconds = 300
#   sqs_managed_sse_enabled   = true

#   tags = {
#     Name = "${var.cluster_name}-karpenter-interruption"
#   }
# }

# resource "aws_sqs_queue_policy" "karpenter_interruption" {
#   queue_url = aws_sqs_queue.karpenter_interruption.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Principal = {
#           Service = [
#             "events.amazonaws.com",
#             "sqs.amazonaws.com"
#           ]
#         }
#         Action   = "sqs:SendMessage"
#         Resource = aws_sqs_queue.karpenter_interruption.arn
#       }
#     ]
#   })
# }

# # EventBridge rules for interruption handling
# resource "aws_cloudwatch_event_rule" "karpenter_interruption_scheduled_change" {
#   name = "${var.cluster_name}-karpenter-interruption-scheduled-change"

#   event_pattern = jsonencode({
#     source      = ["aws.health"]
#     detail-type = ["AWS Health Event"]
#   })

#   tags = {
#     Name = "${var.cluster_name}-karpenter-interruption-scheduled-change"
#   }
# }

# resource "aws_cloudwatch_event_target" "karpenter_interruption_scheduled_change" {
#   rule      = aws_cloudwatch_event_rule.karpenter_interruption_scheduled_change.name
#   target_id = "KarpenterInterruptionQueueTarget"
#   arn       = aws_sqs_queue.karpenter_interruption.arn
# }

# resource "aws_cloudwatch_event_rule" "karpenter_interruption_spot_interruption" {
#   name = "${var.cluster_name}-karpenter-interruption-spot-interruption"

#   event_pattern = jsonencode({
#     source      = ["aws.ec2"]
#     detail-type = ["EC2 Spot Instance Interruption Warning"]
#   })

#   tags = {
#     Name = "${var.cluster_name}-karpenter-interruption-spot-interruption"
#   }
# }

# resource "aws_cloudwatch_event_target" "karpenter_interruption_spot_interruption" {
#   rule      = aws_cloudwatch_event_rule.karpenter_interruption_spot_interruption.name
#   target_id = "KarpenterInterruptionQueueTarget"
#   arn       = aws_sqs_queue.karpenter_interruption.arn
# }

# resource "aws_cloudwatch_event_rule" "karpenter_interruption_instance_state_change" {
#   name = "${var.cluster_name}-karpenter-interruption-instance-state-change"

#   event_pattern = jsonencode({
#     source      = ["aws.ec2"]
#     detail-type = ["EC2 Instance State-change Notification"]
#   })

#   tags = {
#     Name = "${var.cluster_name}-karpenter-interruption-instance-state-change"
#   }
# }

# resource "aws_cloudwatch_event_target" "karpenter_interruption_instance_state_change" {
#   rule      = aws_cloudwatch_event_rule.karpenter_interruption_instance_state_change.name
#   target_id = "KarpenterInterruptionQueueTarget"
#   arn       = aws_sqs_queue.karpenter_interruption.arn
# }

# # Karpenter Helm Release
# resource "helm_release" "karpenter" {
#   name       = "karpenter"
#   repository = "oci://public.ecr.aws/karpenter"
#   chart      = "karpenter"
#   namespace  = "karpenter"
#   version    = "0.37.0"

#   create_namespace = true

#   values = [
#     yamlencode({
#       serviceAccount = {
#         annotations = {
#           "eks.amazonaws.com/role-arn" = aws_iam_role.karpenter_controller.arn
#         }
#       }
#       settings = {
#         clusterName                = aws_eks_cluster.main.name
#         clusterEndpoint           = aws_eks_cluster.main.endpoint
#         interruptionQueue         = aws_sqs_queue.karpenter_interruption.name
#         featureGates = {
#           drift = true
#         }
#       }
#       # Enable webhook for security
#       webhook = {
#         enabled = true
#       }
#       # Resource limits
#       resources = {
#         requests = {
#           cpu    = "1"
#           memory = "1Gi"
#         }
#         limits = {
#           cpu    = "1"
#           memory = "1Gi"
#         }
#       }
#       # Node affinity to run on managed nodes
#       affinity = {
#         nodeAffinity = {
#           requiredDuringSchedulingIgnoredDuringExecution = {
#             nodeSelectorTerms = [
#               {
#                 matchExpressions = [
#                   {
#                     key      = "karpenter.sh/nodepool"
#                     operator = "DoesNotExist"
#                   }
#                 ]
#               }
#             ]
#           }
#         }
#       }
#       # Tolerations
#       tolerations = [
#         {
#           key      = "CriticalAddonsOnly"
#           operator = "Exists"
#         }
#       ]
#     })
#   ]

#   depends_on = [
#     aws_eks_node_group.managed_node_group,
#     aws_iam_role.karpenter_controller,
#     aws_sqs_queue.karpenter_interruption
#   ]
# }

# # karpenter-nodepool.tf

# # Karpenter NodeClass
# resource "kubectl_manifest" "karpenter_nodeclass" {
#   yaml_body = yamlencode({
#     apiVersion = "karpenter.k8s.aws/v1beta1"
#     kind       = "EC2NodeClass"
#     metadata = {
#       name = "${var.cluster_name}-nodeclass"
#     }
#     spec = {
#       # AMI selection
#       amiFamily = "AL2"
      
#       # Subnet selection
#       subnetSelectorTerms = [
#         {
#           tags = {
#             "karpenter.sh/discovery" = var.cluster_name
#           }
#         }
#       ]
      
#       # Security group selection
#       securityGroupSelectorTerms = [
#         {
#           tags = {
#             "karpenter.sh/discovery" = var.cluster_name
#           }
#         }
#       ]
      
#       # Instance profile
#       role = aws_iam_role.karpenter_node_instance_profile.name
      
#       # User data for node initialization
#       userData = base64encode(templatefile("${path.module}/karpenter-userdata.sh", {
#         cluster_name = var.cluster_name
#         endpoint     = aws_eks_cluster.main.endpoint
#         certificate_authority = aws_eks_cluster.main.certificate_authority[0].data
#       }))
      
#       # Block device mappings with KMS encryption
#       blockDeviceMappings = [
#         {
#           deviceName = "/dev/xvda"
#           ebs = {
#             volumeSize          = 20
#             volumeType          = "gp3"
#             iops               = 3000
#             throughput         = 125
#             encrypted          = true
#             kmsKeyID           = var.kms_key_arn
#             deleteOnTermination = true
#           }
#         }
#       ]
      
#       # Instance metadata options
#       metadataOptions = {
#         httpEndpoint            = "enabled"
#         httpProtocolIPv6        = "disabled"
#         httpPutResponseHopLimit = 2
#         httpTokens              = "required"
#       }
      
#       # Tags for instances
#       tags = {
#         Name                                        = "${var.cluster_name}-karpenter-node"
#         "karpenter.sh/discovery"                   = var.cluster_name
#         "kubernetes.io/cluster/${var.cluster_name}" = "owned"
#       }
#     }
#   })

#   depends_on = [
#     helm_release.karpenter,
#     aws_iam_instance_profile.karpenter_node_instance_profile
#   ]
# }

# # Default NodePool for general workloads
# resource "kubectl_manifest" "karpenter_nodepool_default" {
#   yaml_body = yamlencode({
#     apiVersion = "karpenter.sh/v1beta1"
#     kind       = "NodePool"
#     metadata = {
#       name = "${var.cluster_name}-default"
#     }
#     spec = {
#       # Template for nodes
#       template = {
#         metadata = {
#           labels = {
#             "node-type" = "karpenter-default"
#           }
#           annotations = {
#             "karpenter.sh/do-not-evict" = "false"
#           }
#         }
#         spec = {
#           # Node class reference
#           nodeClassRef = {
#             apiVersion = "karpenter.k8s.aws/v1beta1"
#             kind       = "EC2NodeClass"
#             name       = "${var.cluster_name}-nodeclass"
#           }
          
#           # Instance requirements
#           requirements = [
#             {
#               key      = "kubernetes.io/arch"
#               operator = "In"
#               values   = ["amd64"]
#             },
#             {
#               key      = "kubernetes.io/os"
#               operator = "In"
#               values   = ["linux"]
#             },
#             {
#               key      = "karpenter.sh/capacity-type"
#               operator = "In"
#               values   = ["spot", "on-demand"]
#             },
#             {
#               key      = "node.kubernetes.io/instance-type"
#               operator = "In"
#               values   = [
#                 "m5.large", "m5.xlarge", "m5.2xlarge", "m5.4xlarge",
#                 "m5a.large", "m5a.xlarge", "m5a.2xlarge", "m5a.4xlarge",
#                 "m6i.large", "m6i.xlarge", "m6i.2xlarge", "m6i.4xlarge",
#                 "c5.large", "c5.xlarge", "c5.2xlarge", "c5.4xlarge",
#                 "c5a.large", "c5a.xlarge", "c5a.2xlarge", "c5a.4xlarge",
#                 "c6i.large", "c6i.xlarge", "c6i.2xlarge", "c6i.4xlarge"
#               ]
#             }
#           ]
          
#           # Node properties
#           nodeProperties = {
#             # Taints for specific workloads (optional)
#             taints = []
#           }
#         }
#       }
      
#       # Disruption settings
#       disruption = {
#         consolidationPolicy = "WhenUnderutilized"
#         consolidateAfter    = "30s"
#         expireAfter         = "30m"
#       }
      
#       # Limits
#       limits = {
#         cpu    = "1000"
#         memory = "1000Gi"
#       }
#     }
#   })

#   depends_on = [
#     kubectl_manifest.karpenter_nodeclass
#   ]
# }

# # Spot NodePool for cost-optimized workloads
# resource "kubectl_manifest" "karpenter_nodepool_spot" {
#   yaml_body = yamlencode({
#     apiVersion = "karpenter.sh/v1beta1"
#     kind       = "NodePool"
#     metadata = {
#       name = "${var.cluster_name}-spot"
#     }
#     spec = {
#       template = {
#         metadata = {
#           labels = {
#             "node-type" = "karpenter-spot"
#           }
#           annotations = {
#             "karpenter.sh/do-not-evict" = "false"
#           }
#         }
#         spec = {
#           nodeClassRef = {
#             apiVersion = "karpenter.k8s.aws/v1beta1"
#             kind       = "EC2NodeClass"
#             name       = "${var.cluster_name}-nodeclass"
#           }
          
#           requirements = [
#             {
#               key      = "kubernetes.io/arch"
#               operator = "In"
#               values   = ["amd64"]
#             },
#             {
#               key      = "kubernetes.io/os"
#               operator = "In"
#               values   = ["linux"]
#             },
#             {
#               key      = "karpenter.sh/capacity-type"
#               operator = "In"
#               values   = ["spot"]
#             },
#             {
#               key      = "node.kubernetes.io/instance-type"
#               operator = "In"
#               values   = [
#                 "m5.large", "m5.xlarge", "m5.2xlarge",
#                 "m5a.large", "m5a.xlarge", "m5a.2xlarge",
#                 "c5.large", "c5.xlarge", "c5.2xlarge",
#                 "c5a.large", "c5a.xlarge", "c5a.2xlarge"
#               ]
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
#         consolidateAfter    = "30s"
#         expireAfter         = "10m"
#       }
      
#       limits = {
#         cpu    = "500"
#         memory = "500Gi"
#       }
#     }
#   })

#   depends_on = [
#     kubectl_manifest.karpenter_nodeclass
#   ]
# }
