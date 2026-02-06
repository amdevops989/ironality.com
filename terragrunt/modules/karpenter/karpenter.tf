resource "kubernetes_namespace" "karpenter" {
  metadata {
    name = var.karpenter_namespace
  }
}

resource "kubernetes_service_account" "karpenter_sa" {
  metadata {
    name      = var.service_account_name
    namespace = kubernetes_namespace.karpenter.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.karpenter_controller.arn
    }
  }
}

resource "helm_release" "karpenter" {
  name       = "karpenter"
  repository = "https://charts.karpenter.sh"
  chart      = "karpenter"
  version    = var.helm_chart_version
  namespace  = kubernetes_namespace.karpenter.metadata[0].name
  create_namespace = false
  create_crds = true


  values = [
    yamlencode({
      serviceAccount = {
        create = false
        name   = kubernetes_service_account.karpenter_sa.metadata[0].name
      }
      settings = {
        clusterName = var.cluster_name
        clusterEndpoint = var.k8s_host
      }
    })
  ]
}
