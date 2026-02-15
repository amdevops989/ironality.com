
variable vpc_cidr_block {
  type        = string
  default     = ""
}

variable env {
}

variable "vpc_id" {
  description = "VPC ID where EKS will be deployed"
  type        = string
}

variable "private_subnets" {
  description = "Private subnet IDs for worker nodes"
  type        = list(string)
}

variable "region" {
  type        = string
  description = "AWS region"
}

variable "profile" {
  type        = string
  description = "AWS CLI profile"
}

