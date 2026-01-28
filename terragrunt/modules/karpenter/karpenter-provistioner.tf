resource "kubernetes_manifest" "karpenter_provisioner" {
  manifest = {
    apiVersion = "karpenter.sh/v1alpha5"
    kind       = "Provisioner"
    metadata = {
      name = "spot-provisioner"
    }
    spec = {
      requirements = [
        {
          key      = "karpenter.sh/capacity-type"
          operator = "In"
          values   = ["spot"]

        },
        {
          key      = "kubernetes.io/instance-type"
          operator = "In"
          values   = ["m5.large","m5.xlarge"]
        }
      ]
      limits = {
        resources = {
          cpu = "1000"
        }
      }
      provider = {
        subnetSelector = {
          "karpenter.sh/discovery" = var.cluster_name
        }
        securityGroupSelector = {
          "kubernetes.io/cluster/${var.cluster_name}" = "owned"
        }
      }
      ttlSecondsAfterEmpty = 30
    }
  }
}
