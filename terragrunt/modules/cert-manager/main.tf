# -----------------------------
# Namespace for cert-manager
# -----------------------------
resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = var.k8s_namespace
  }
}

# -----------------------------
# Service Account for cert-manager
# -----------------------------
resource "kubernetes_service_account" "cert_manager_sa" {
  metadata {
    name      = var.service_account_name
    namespace = kubernetes_namespace.cert_manager.metadata[0].name
    labels = {
      "app.kubernetes.io/managed-by" = "Helm"
    }
    annotations = {
      "eks.amazonaws.com/role-arn"        = var.oidc_provider_arn
      "meta.helm.sh/release-name"         = var.k8s_namespace
      "meta.helm.sh/release-namespace"    = var.k8s_namespace
    }
  }
}


# -----------------------------
# Helm Release for cert-manager CRDs
# -----------------------------
# resource "helm_release" "cert_manager_crds" {
#   name       = "cert-manager-crds"
#   repository = "https://charts.jetstack.io"
#   chart      = "cert-manager-crds"
#   namespace  = kubernetes_namespace.cert_manager.metadata[0].name
#   version    = "v1.19.3"

#   create_namespace = false
# }


# -----------------------------
# Helm Release for cert-manager controller
# -----------------------------
resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  namespace  = kubernetes_namespace.cert_manager.metadata[0].name
  version    = "v1.19.3"

  create_namespace = false

  values = [
    yamlencode({
      serviceAccount = {
        create = true
        name   = kubernetes_service_account.cert_manager_sa.metadata[0].name
      }
    })
  ]

  depends_on = [
    kubernetes_service_account.cert_manager_sa
  ]
}

