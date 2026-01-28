variable "project_name" {
  description = "Project name prefix for resources"
  type        = string
}

variable "env" {
  description = "Environment (dev, stg, prod)"
  type        = string
}

variable "cidr_block" {
  description = "VPC CIDR block"
  type        = string
}



variable "az_count" {
  description = "Number of AZs to use"
  type        = number
  default     = 2
}

variable "enable_nat" {
  description = "Enable NAT gateways for private subnets"
  type        = bool
  default     = false
}

variable "single_nat_gw" {
  description = "Use a single shared NAT gateway (cost-effective)"
  type        = bool
  default     = true
}
