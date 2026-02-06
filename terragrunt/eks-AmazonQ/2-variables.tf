# Variables
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "my-eks-cluster"
}
variable "environment" {
  description = "Name of the env"
  type        = string
  default     = "dev"
}

variable "profile" {
  type = string

}

variable "kms_key_arn" {
  type = string

}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "node_group_name" {
  description = "Name of the EKS node group"
  type        = string
  default     = "managed-nodes"
}

variable "instance_types" {
  description = "List of instance types for the node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "desired_capacity" {
  description = "Desired number of nodes"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum number of nodes"
  type        = number
  default     = 4
}

variable "min_capacity" {
  description = "Minimum number of nodes"
  type        = number
  default     = 1
}

variable "volume_size" {
  description = "Size of the root volume in GB"
  type        = number
  default     = 50
}

variable "key_pair_name" {
  description = "EC2 Key Pair name for SSH access"
  type        = string
  default     = ""
}