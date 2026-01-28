# ------------------------------------------------------------
# 📤 Outputs
# ------------------------------------------------------------
output "cluster_name" {
  value = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.this.endpoint
}

output "cluster_ca_certificate" {
  value = aws_eks_cluster.this.certificate_authority[0].data
}

output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.oidc.arn
}

output "oidc_provider_url" {
  value = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

output "node_group_name" {
  value = aws_eks_node_group.default.node_group_name
}
output "cluster_token" {
  description = "Authentication token used by Kubernetes provider"
  value       = data.aws_eks_cluster_auth.cluster.token
  sensitive   = true
}