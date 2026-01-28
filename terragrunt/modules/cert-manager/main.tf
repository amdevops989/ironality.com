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
    annotations = {
      "eks.amazonaws.com/role-arn" = var.oidc_provider_arn
    }
  }
}

# -----------------------------
# Helm Release for cert-manager
# -----------------------------
resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  namespace  = kubernetes_namespace.cert_manager.metadata[0].name
  version    = "v1.13.1"

  create_namespace = false

  values = [
    yamlencode({
      installCRDs = true
      serviceAccount = {
        create = false
        name   = kubernetes_service_account.cert_manager_sa.metadata[0].name
      }
    })
  ]

  depends_on = [
    kubernetes_service_account.cert_manager_sa
  ]
}
# -----------------------------
# Production ClusterIssuer (DNS-01)
# -----------------------------
resource "kubernetes_manifest" "production_cluster_issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "production-cluster-issuer"
    }
    spec = {
      acme = {
        server = "https://acme-v02.api.letsencrypt.org/directory"
        email  = "am.devops989@gmail.com"  # <-- change to your real email
        privateKeySecretRef = {
          name = "production-cluster-issuer-key"
        }
        solvers = [{
          selector = {}
          dns01 = {
            route53 = {
              region = var.region
            }
          }
        }]
      }
    }
  }

  depends_on = [
    helm_release.cert_manager
  ]

  lifecycle {
    ignore_changes = [
      "manifest[0].spec.acme.solvers[0].dns01.route53.secretAccessKeySecretRef"
    ]
  }
}

# -----------------------------
# Production ClusterIssuer (HTTP-01)
# -----------------------------
resource "kubernetes_manifest" "production_cluster_issuer_http" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "production-cluster-issuer-http"
    }
    spec = {
      acme = {
        server = "https://acme-v02.api.letsencrypt.org/directory"
        email  = "am.devops989@gmail.com"  # <-- Replace with real email
        privateKeySecretRef = {
          name = "production-cluster-issuer-http-key"
        }
        solvers = [
          {
            selector = {}
            http01 = {
              ingress = {
                class = "istio"
              }
            }
          }
        ]
      }
    }
  }

  depends_on = [
    helm_release.cert_manager
  ]
}

# -----------------------------
# Staging ClusterIssuer (HTTP-01)
# -----------------------------
resource "kubernetes_manifest" "staging_cluster_issuer_http" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "staging-cluster-issuer-http"
    }
    spec = {
      acme = {
        server = "https://acme-staging-v02.api.letsencrypt.org/directory"
        email  = "am.devops989@gmail.com"  # <-- Replace with real email
        privateKeySecretRef = {
          name = "staging-cluster-issuer-http-key"
        }
        solvers = [
          {
            selector = {}
            http01 = {
              ingress = {
                class = "istio"
              }
            }
          }
        ]
      }
    }
  }

  depends_on = [
    helm_release.cert_manager
  ]
}
