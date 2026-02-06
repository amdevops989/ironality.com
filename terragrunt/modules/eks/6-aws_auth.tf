locals {
  node_role_map = [{
    rolearn  = aws_iam_role.eks_node_role.arn
    username = "system:node:{{EC2PrivateDNSName}}"
    groups   = ["system:bootstrappers", "system:nodes"]
  }]

  admin_role_map = [
    for role in var.admin_roles : {
      rolearn  = role
      username = "{{SessionName}}"
      groups   = ["system:masters"]
    }
  ]

  developer_role_map = [
    for role in var.developer_roles : {
      rolearn  = role
      username = "{{SessionName}}"
      groups   = ["${var.env}-developers"]
    }
  ]

  map_roles = concat(
    local.node_role_map,
    local.admin_role_map,
    local.developer_role_map
  )
}

resource "kubernetes_config_map_v1_data" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode(local.map_roles)
  }

  force = true

  depends_on = [
    aws_eks_cluster.this,
    aws_eks_node_group.default
  ]
}
