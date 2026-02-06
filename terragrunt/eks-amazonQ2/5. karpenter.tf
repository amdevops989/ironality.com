# Karpenter for cost-effective spot instances
module "karpenter" {
  source = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 20.0"

  cluster_name = module.eks.cluster_name

  # Disable SQS queue creation as requested
  enable_irsa            = true
  irsa_oidc_provider_arn = module.eks.oidc_provider_arn
  
  # Create service account
  create_iam_role = true
  iam_role_name   = "${var.cluster_name}-karpenter-controller-role"
  
  # Node IAM role
  create_node_iam_role = true
  node_iam_role_name   = "${var.cluster_name}-karpenter-node-role"

  tags = var.tags
}

# Karpenter Helm Chart
resource "helm_release" "karpenter" {
  namespace        = "karpenter"
  create_namespace = true

  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = "0.37.0"

  values = [
    <<-EOT
    settings:
      clusterName: ${module.eks.cluster_name}
      clusterEndpoint: ${module.eks.cluster_endpoint}
      interruptionQueue: ""  # Disable SQS queue
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: ${module.karpenter.iam_role_arn}
    EOT
  ]

  depends_on = [
    module.eks
  ]
}

# Karpenter NodeClass with encrypted volumes (CORRECTED)
resource "kubectl_manifest" "karpenter_nodeclass" {
  yaml_body = <<-YAML
apiVersion: karpenter.k8s.aws/v1beta1
kind: EC2NodeClass
metadata:
  name: cost-effective-nodeclass
spec:
  amiFamily: AL2023

  subnetSelectorTerms:
    - tags:
        karpenter.sh/discovery: ${module.eks.cluster_name}

  securityGroupSelectorTerms:
    - tags:
        karpenter.sh/discovery: ${module.eks.cluster_name}

  blockDeviceMappings:
    - deviceName: /dev/xvda
      ebs:
        volumeSize: 20Gi
        volumeType: gp3
        iops: 3000
        throughput: 150
        encrypted: true
        deleteOnTermination: true

  role: ${module.karpenter.node_iam_role_name}

  tags:
    Name: "${var.cluster_name}-karpenter-node"
    Environment: ${var.environment}
YAML

  depends_on = [helm_release.karpenter]
}


# # CORRECTED Karpenter NodePool for spot instances
# resource "kubectl_manifest" "karpenter_nodepool" {
#   yaml_body = <<-YAML
#     apiVersion: karpenter.sh/v1beta1
#     kind: NodePool
#     metadata:
#       name: cost-effective-spot
#     spec:
#       template:
#         metadata:
#           labels:
#             node-type: "spot"
#         spec:
#           requirements:
#             - key: kubernetes.io/arch
#               operator: In
#               values: ["amd64"]
#             - key: kubernetes.io/os
#               operator: In
#               values: ["linux"]
#             - key: karpenter.sh/capacity-type
#               operator: In
#               values: ["spot"]
#             - key: karpenter.k8s.aws/instance-category
#               operator: In
#               values: ["m", "c", "r"]
#             - key: karpenter.k8s.aws/instance-generation
#               operator: Gt
#               values: ["3"]
#             - key: node.kubernetes.io/instance-type
#               operator: In
#               values: 
#                 - "m5.medium"
#                 - "m5a.medium" 
#                 - "m5d.medium"
#                 - "m5n.medium"
#                 - "m4.large"
#                 - "c5.large"
#                 - "c5a.large"
#                 - "c4.large"
#           nodeClassRef:
#             apiVersion: karpenter.k8s.aws/v1beta1
#             kind: EC2NodeClass
#             name: cost-effective-nodeclass
#           taints:
#             - key: spot
#               value: "true"
#               effect: NoSchedule
#       limits:
#         cpu: 1000
#       disruption:
#         consolidationPolicy: WhenEmpty
#         consolidateAfter: 30s
#         expireAfter: 2160h # 90 days
#   YAML

#   depends_on = [
#     kubectl_manifest.karpenter_nodeclass
#   ]
# }

# Alternative: More flexible NodePool
resource "kubectl_manifest" "karpenter_nodepool_flexible" {
  yaml_body = <<-YAML
apiVersion: karpenter.sh/v1beta1
kind: NodePool
metadata:
  name: cost-effective-spot-flexible
spec:
  template:
    metadata:
      labels:
        node-type: spot
    spec:
      requirements:
        - key: kubernetes.io/arch
          operator: In
          values: ["amd64"]
        - key: kubernetes.io/os
          operator: In
          values: ["linux"]
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["spot"]
        - key: karpenter.k8s.aws/instance-category
          operator: In
          values: ["m","c","r","t"]
        - key: karpenter.k8s.aws/instance-generation
          operator: Gt
          values: ["3"]
        - key: karpenter.k8s.aws/instance-size
          operator: In
          values: ["medium","large","xlarge"]
      nodeClassRef:
        apiVersion: karpenter.k8s.aws/v1beta1
        kind: EC2NodeClass
        name: cost-effective-nodeclass
      taints:
        - key: spot
          value: "true"
          effect: NoSchedule
  limits:
    cpu: 1000
  disruption:
    consolidationPolicy: WhenEmpty
    consolidateAfter: 30s
    expireAfter: 2160h
YAML

  depends_on = [
    kubectl_manifest.karpenter_nodeclass
  ]
}
