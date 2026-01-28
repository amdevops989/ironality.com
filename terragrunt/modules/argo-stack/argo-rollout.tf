# -----------------------------
# Helm Release for Argo Rollouts
# -----------------------------
resource "helm_release" "argo_rollouts" {
  name       = "argo-rollouts"
  namespace  = "argo-rollouts"
  create_namespace = true
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-rollouts"
  version    = "2.40.5" # replace with latest stable if needed

  # Optional: set values
  set {
    name  = "controller.replicaCount"
    value = "1"
  }

  set {
    name  = "controller.metrics.enabled"
    value = "true"
  }

  set {
    name  = "controller.metrics.serviceMonitor.enabled"
    value = "false"  ## make it true when you install prometheus
  }
}