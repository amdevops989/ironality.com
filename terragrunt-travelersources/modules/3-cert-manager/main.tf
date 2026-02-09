# -----------------------------
# Namespace for cert-manager
# -----------------------------

# resource "kubectl_manifest" "cert_manager_namespace" {
#   yaml_body = <<YAML
# apiVersion: v1
# kind: Namespace
# metadata:
#   name: ${var.k8s_namespace}
# YAML
# }

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
      "meta.helm.sh/release-name"         = var.release-name
      "meta.helm.sh/release-namespace"    = var.k8s_namespace
    }
  }
}



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
      installCRDs = true
    })
  ]

  depends_on = [
    kubernetes_service_account.cert_manager_sa
  ]
}

# -----------------------------
# Production ClusterIssuer (DNS-01)
# -----------------------------
resource "kubectl_manifest" "production_cluster_issuer" {
  yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: production-cluster-issuer
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: am.devops989@gmail.com
    privateKeySecretRef:
      name: production-cluster-issuer-key
    solvers:
      - dns01:
          route53:
            region: ${var.region}
YAML

  depends_on = [
    helm_release.cert_manager
  ]
}

# -----------------------------
# Production ClusterIssuer (HTTP-01)
# -----------------------------
resource "kubectl_manifest" "production_cluster_issuer_http" {
  yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: production-cluster-issuer-http
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: am.devops989@gmail.com
    privateKeySecretRef:
      name: production-cluster-issuer-http-key
    solvers:
      - http01:
          ingress:
            class: istio
YAML

  depends_on = [
    helm_release.cert_manager
  ]
}

# -----------------------------
# Staging ClusterIssuer (HTTP-01)
# -----------------------------
resource "kubectl_manifest" "staging_cluster_issuer_http" {
  yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: staging-cluster-issuer-http
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: am.devops989@gmail.com
    privateKeySecretRef:
      name: staging-cluster-issuer-http-key
    solvers:
      - http01:
          ingress:
            class: istio
YAML

  depends_on = [
    helm_release.cert_manager
  ]
}
