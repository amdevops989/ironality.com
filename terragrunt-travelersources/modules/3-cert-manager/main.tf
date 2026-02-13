# -----------------------------
# Namespace for cert-manager
# -----------------------------
resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = var.k8s_namespace
  }
}

resource "aws_iam_role" "cert_manager_route53" {
  name = "cert-manager-route53"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn   # OIDC provider ARN from EKS
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(var.oidc_provider_url, "https://", "")}:sub" = "system:serviceaccount:${var.k8s_namespace}:${var.service_account_name}"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "cert_manager_route53_policy" {
  name        = "cert-manager-route53-policy"
  description = "Allow cert-manager to manage Route53 records"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "route53:GetChange"
        Resource = "arn:aws:route53:::change/*"
      },
      {
        Effect   = "Allow"
        Action   = [
          "route53:ListHostedZones",
          "route53:ListHostedZonesByName"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = "route53:ListResourceRecordSets"
        Resource = "arn:aws:route53:::hostedzone/*"
      },
      {
        Effect   = "Allow"
        Action   = "route53:ChangeResourceRecordSets"
        Resource = "arn:aws:route53:::hostedzone/*"
      }
    ]
  })
}



resource "aws_iam_role_policy_attachment" "cert_manager_attach" {
  role       = aws_iam_role.cert_manager_route53.name
  policy_arn = aws_iam_policy.cert_manager_route53_policy.arn
}

# -----------------------------
# Service Account for cert-manager
# -----------------------------
resource "kubernetes_service_account" "cert_manager_sa" {
  metadata {
    name      = var.service_account_name
    namespace = kubernetes_namespace.cert_manager.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.cert_manager_route53.arn
    }
  }

  automount_service_account_token = true
}

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

      # -----------------------
      # Force pods to main node group
      # -----------------------
      nodeSelector = {
        role = "main"   # your MNG label
      }

      webhook = {
        nodeSelector = {
          role = "main"
        }
      }

      cainjector = {
        nodeSelector = {
          role = "main"
        }
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
      - selector: {}
        dns01:
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
      - selector: {}
        http01:
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
      - selector: {}
        http01:
          ingress:
            class: istio
YAML

  depends_on = [
    helm_release.cert_manager
  ]
}
