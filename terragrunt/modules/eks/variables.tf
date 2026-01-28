variable "cluster_name" {}
variable "region" {}
variable "profile" {}
variable "env" {}
variable "vpc_id" {}
variable "private_subnets" {
  type = list(string)
}
variable "public_subnets" {
  type = list(string)
  default = []
}

variable "project_name" {
  description = "Project name prefix for resources"
  type        = string
}
variable "node_instance_type" {
  default = "t3.small"
}
variable "node_desired_capacity" {
  default = 1
}
variable "node_min_capacity" {
  default = 1
}
variable "node_max_capacity" {
  default = 2
}
variable "ssh_key_name" {
  default = ""
}
variable "kms_key_id" {}
variable "tags" {
  type    = map(string)
  default = {}
}


# -----------------------------
# Variables
# -----------------------------
variable "admin_roles" {
  description = "List of AWS IAM role ARNs for SSO admins"
  type        = list(string)
  default     = [
    "arn:aws:iam::272495906318:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_AdministratorAccess_ad80597e4fb78530"
  ]
}

variable "developer_roles" {
  description = "List of AWS IAM role ARNs for SSO developers"
  type        = list(string)
  default = [
    "arn:aws:iam::272495906318:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_Developers_3bffcc1f1b28d3b2"
  ]
}

# variable "env" {
#   description = "Environment name, used for developer RBAC group"
#   type        = string
#   default     = "dev"
# }
