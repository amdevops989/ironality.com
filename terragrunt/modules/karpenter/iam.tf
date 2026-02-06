# Karpenter Controller IAM Role
resource "aws_iam_role" "karpenter_controller" {
  name = "${var.cluster_name}-karpenter-controller"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = {
        Federated = var.oidc_provider_arn
      }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(var.oidc_provider_url, "https://","")}:sub" = "system:serviceaccount:karpenter:karpenter"
        }
      }
    }]
  })
}

# Attach managed Karpenter policies
resource "aws_iam_role_policy_attachment" "karpenter_controller_attach" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "karpenter_node_attach" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "karpenter_provisioner_attach" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}
