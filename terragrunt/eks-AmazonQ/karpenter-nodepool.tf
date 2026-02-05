# karpenter-nodepool.tf

# Karpenter NodeClass
resource "kubectl_manifest" "karpenter_nodeclass" {
  yaml_body = yamlencode({
    apiVersion = "karpenter.k8s.aws/v1beta1"
    kind       = "EC2NodeClass"
    metadata = {
      name = "${var.cluster_name}-nodeclass"
    }
    spec = {
      amiFamily = "AL2"
      
      subnetSelectorTerms = [
        {
          tags = {
            "karpenter.sh/discovery" = var.cluster_name
          }
        }
      ]
      
      securityGroupSelectorTerms = [
        {
          tags = {
            "karpenter.sh/discovery" = var.cluster_name
          }
        }
      ]
      
      # Using existing node group role name
      role = aws_iam_role.node_group.name
      
      userData = base64encode(templatefile("${path.module}/karpenter-userdata.sh", {
        cluster_name = var.cluster_name
        endpoint     = aws_eks_cluster.main.endpoint
        certificate_authority = aws_eks_cluster.main.certificate_authority[0].data
      }))
      
      blockDeviceMappings = [
        {
          deviceName = "/dev/xvda"
          ebs = {
            volumeSize          = 20
            volumeType          = "gp3"
            iops               = 3000
            throughput         = 125
            encrypted          = true
            kmsKeyID           = var.kms_key_arn
            deleteOnTermination = true
          }
        }
      ]
      
      metadataOptions = {
        httpEndpoint            = "enabled"
        httpProtocolIPv6        = "disabled"
        httpPutResponseHopLimit = 2
        httpTokens              = "required"
      }
      
      tags = {
        Name                                        = "${var.cluster_name}-karpenter-node"
        "karpenter.sh/discovery"                   = var.cluster_name
        "kubernetes.io/cluster/${var.cluster_name}" = "owned"
      }
    }
  })

  depends_on = [
    helm_release.karpenter,
    aws_iam_instance_profile.karpenter_node_instance_profile
  ]
}

# Default NodePool
resource "kubectl_manifest" "karpenter_nodepool_default" {
  yaml_body = yamlencode({
    apiVersion = "karpenter.sh/v1beta1"
    kind       = "NodePool"
    metadata = {
      name = "${var.cluster_name}-default"
    }
    spec = {
      template = {
        metadata = {
          labels = {
            "node-type" = "karpenter-default"
          }
          annotations = {
            "karpenter.sh/do-not-evict" = "false"
          }
        }
        spec = {
          nodeClassRef = {
            apiVersion = "karpenter.k8s.aws/v1beta1"
            kind       = "EC2NodeClass"
            name       = "${var.cluster_name}-nodeclass"
          }
          
          requirements = [
            {
              key      = "kubernetes.io/arch"
              operator = "In"
              values   = ["amd64"]
            },
            {
              key      = "kubernetes.io/os"
              operator = "In"
              values   = ["linux"]
            },
            {
              key      = "karpenter.sh/capacity-type"
              operator = "In"
              values   = ["spot", "on-demand"]
            },
            {
              key      = "node.kubernetes.io/instance-type"
              operator = "In"
              values   = [
                "m5.large", "m5.xlarge", "m5.2xlarge", "m5.4xlarge",
                "m5a.large", "m5a.xlarge", "m5a.2xlarge", "m5a.4xlarge",
                "m6i.large", "m6i.xlarge", "m6i.2xlarge", "m6i.4xlarge",
                "c5.large", "c5.xlarge", "c5.2xlarge", "c5.4xlarge",
                "c5a.large", "c5a.xlarge", "c5a.2xlarge", "c5a.4xlarge",
                "c6i.large", "c6i.xlarge", "c6i.2xlarge", "c6i.4xlarge"
              ]
            }
          ]
          
          nodeProperties = {
            taints = []
          }
        }
      }
      
      disruption = {
        consolidationPolicy = "WhenUnderutilized"
        consolidateAfter    = "30s"
        expireAfter         = "30m"
      }
      
      limits = {
        cpu    = "1000"
        memory = "1000Gi"
      }
    }
  })

  depends_on = [
    kubectl_manifest.karpenter_nodeclass
  ]
}

# Spot NodePool
resource "kubectl_manifest" "karpenter_nodepool_spot" {
  yaml_body = yamlencode({
    apiVersion = "karpenter.sh/v1beta1"
    kind       = "NodePool"
    metadata = {
      name = "${var.cluster_name}-spot"
    }
    spec = {
      template = {
        metadata = {
          labels = {
            "node-type" = "karpenter-spot"
          }
          annotations = {
            "karpenter.sh/do-not-evict" = "false"
          }
        }
        spec = {
          nodeClassRef = {
            apiVersion = "karpenter.k8s.aws/v1beta1"
            kind       = "EC2NodeClass"
            name       = "${var.cluster_name}-nodeclass"
          }
          
          requirements = [
            {
              key      = "kubernetes.io/arch"
              operator = "In"
              values   = ["amd64"]
            },
            {
              key      = "kubernetes.io/os"
              operator = "In"
              values   = ["linux"]
            },
            {
              key      = "karpenter.sh/capacity-type"
              operator = "In"
              values   = ["spot"]
            },
            {
              key      = "node.kubernetes.io/instance-type"
              operator = "In"
              values   = [
                "m5.large", "m5.xlarge", "m5.2xlarge",
                "m5a.large", "m5a.xlarge", "m5a.2xlarge",
                "c5.large", "c5.xlarge", "c5.2xlarge",
                "c5a.large", "c5a.xlarge", "c5a.2xlarge"
              ]
            }
          ]
          
          nodeProperties = {
            taints = [
              {
                key    = "spot-instance"
                value  = "true"
                effect = "NoSchedule"
              }
            ]
          }
        }
      }
      
      disruption = {
        consolidationPolicy = "WhenEmpty"
        consolidateAfter    = "30s"
        expireAfter         = "10m"
      }
      
      limits = {
        cpu    = "500"
        memory = "500Gi"
      }
    }
  })

  depends_on = [
    kubectl_manifest.karpenter_nodeclass
  ]
}
