# aws_eks_cluster: Gets the cluster metadata (like endpoint, ARN, version).

# aws_eks_cluster_auth: Generates a temporary authentication token for the cluster.

# output "eks_token": Exposes the token (marked as sensitive so it’s not printed in logs by default).
data "aws_eks_cluster" "cluster" {
  name = aws_eks_cluster.this.name
}

## added to get token from output
data "aws_eks_cluster_auth" "cluster" {
  name = data.aws_eks_cluster.cluster.name
}

data "tls_certificate" "oidc" {
  url = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "oidc" {
  url             = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.oidc.certificates[0].sha1_fingerprint]
}
