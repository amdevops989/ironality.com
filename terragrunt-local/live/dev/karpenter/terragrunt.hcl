include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

dependency "eks" {
  config_path = "../eks"

  mock_outputs = {
    cluster_name           = "mock-cluster"
    cluster_endpoint       = "https://mock-cluster-endpoint"
    cluster_ca_certificate = "mock-ca-data"
    cluster_token          = "mock-token"
    oidc_provider_arn      = "arn:aws:iam::123456789012:oidc-provider/mock"
    oidc_provider_url      = "https://oidc.mock.eks.amazonaws.com/id/ABC123"
    eks_node_role          = "arn:aws:iam::123456789012:role/travelersources-dev-node-role"
  }

  mock_outputs_merge_with_state = true
}

terraform {
  source = "../../../modules/karpenter"
}

inputs = {
  cluster_name         = dependency.eks.outputs.cluster_name
  region               = include.root.locals.aws_region
  k8s_host             = dependency.eks.outputs.cluster_endpoint
  k8s_ca               = dependency.eks.outputs.cluster_ca_certificate
  k8s_token            = dependency.eks.outputs.cluster_token
  oidc_provider_arn    = dependency.eks.outputs.oidc_provider_arn
  oidc_provider_url    = dependency.eks.outputs.oidc_provider_url
  eks_node_role       = dependency.eks.outputs.eks_node_role   ##
  karpenter_namespace        = "karpenter"
  service_account_name = "karpenter"
  karpenter_instance_types = ["m5.large"]
  karpenter_capacity_type  = "spot"
  karpenter_ttl_seconds_after_empty = "30"
  helm_chart_version   = "0.32.0"
  profile              = include.root.locals.aws_profile
}
