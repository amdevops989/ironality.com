variable "region" {
  type        = string
  description = "AWS region"
}

variable "profile" {
  type        = string
  description = "AWS CLI profile"
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name"
}

variable "k8s_host" {
  type        = string
  description = "Kubernetes cluster endpoint"
}

variable "k8s_ca" {
  type        = string
  description = "Base64-encoded Kubernetes CA"
}

variable "k8s_token" {
  type        = string
  description = "Kubernetes Bearer token"
}

variable "k8s_namespace" {
  type    = string
  default = "cert-manager"
}

variable "service_account_name" {
  type    = string
  default = "cert-manager-sa"
}

variable "oidc_provider_arn" {
  type        = string
  description = "IAM Role ARN for cert-manager service account"
}

variable "argocd_admin_password_hash" {
  description = "bcrypt hash for ArgoCD admin password"
  type        = string
}

variable "argocd_host" {
  description = "Hostname for ArgoCD under the domain (e.g. argocd.travelersources.com)"
  type        = string
  default     = "argocd.travelersources.com"
}
