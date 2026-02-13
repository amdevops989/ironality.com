# Cluster & EKS Info
variable "cluster_name" {
  description = "The name of the EKS cluster where Karpenter will be deployed"
  type        = string
}

variable "eks_node_role" {
  description = "The name of the EKS cluster where Karpenter will be deployed"
  type        = string
}



variable "region" {
  description = "AWS region of the EKS cluster"
  type        = string
  default     = "us-east-1"
}

variable "profile" {
  description = "AWS CLI profile to use for authentication"
  type        = string
  default     = "default"
}

variable "k8s_host" {
  description = "Kubernetes API server endpoint of the EKS cluster"
  type        = string
}

variable "service_account_name" {
  type = string
}

variable "oidc_provider_arn" {
  type = string
}
variable "k8s_ca" {
  description = "Base64 encoded Kubernetes cluster CA certificate"
  type        = string
}

variable "oidc_provider_url" {
  description = "OIDC provider URL of the EKS cluster"
  type        = string
}

# Karpenter Config
variable "karpenter_namespace" {
  description = "Namespace where Karpenter will be deployed"
  type        = string
  default     = "karpenter"
}

variable "helm_chart_version" {
  description = "Version of the Karpenter Helm chart to install"
  type        = string
  default     = "0.30.4" # You can change this to latest stable
}

variable "karpenter_ttl_seconds_after_empty" {
  description = "Time (in seconds) after which empty nodes will be terminated by Karpenter"
  type        = number
  default     = 30
}

# Provisioner Requirements
variable "karpenter_instance_types" {
  description = "Allowed EC2 instance types for Karpenter nodes"
  type        = list(string)
  default     = ["m5.large"]
}

variable "karpenter_capacity_types" {
  description = "Allowed capacity types for Karpenter nodes (spot, on-demand)"
  type        = list(string)
  default     = ["spot"]
}

# Limits
variable "karpenter_cpu_limit" {
  description = "Maximum CPU that Karpenter can provision"
  type        = string
  default     = "1000"
}


