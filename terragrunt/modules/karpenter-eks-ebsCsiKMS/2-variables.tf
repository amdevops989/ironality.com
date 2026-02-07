###############################################################################
# Environment
###############################################################################
variable "region" {
    type = string
}

# variable "aws_account_id" {
#     type = string
# }

###############################################################################
# Cluster
###############################################################################
variable "cluster_name" {
    type = string
}

variable "environment" {
  type        = string
  description = "Name of the environment"
  default     = "dev"
}

variable "app_name" {
  type        = string
  description = "Name of the application"
  default     = "eks-exercise"
}