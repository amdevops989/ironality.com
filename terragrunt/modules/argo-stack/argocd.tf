resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "7.4.4" # Stable, ArgoCD v2.12+

  # ✅ Use ClusterIP (no LoadBalancer)
  set {
    name  = "server.service.type"
    value = "ClusterIP"
  }

  # ✅ Disable ingress completely
  set {
    name  = "server.ingress.enabled"
    value = "false"
  }

  # Optional: metrics and admin password
  set {
    name  = "controller.metrics.enabled"
    value = "true"
  }

  set {
    name  = "server.metrics.enabled"
    value = "true"
  }

  set_sensitive {
    name  = "configs.secret.argocdServerAdminPassword"
    value = var.argocd_admin_password_hash
  }
}
