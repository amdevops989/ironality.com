variable "cluster_name" {}
variable "private_subnets" {
  type = list(string)
}
variable "kms_key_arn" {}
variable "tags" {
  type = map(string)
}

variable "node_instance_type" {}
variable "node_desired_capacity" {}
variable "node_min_capacity" {}
variable "node_max_capacity" {}

variable "admin_roles" {
  type = list(string)
}

variable "developer_roles" {
  type = list(string)
}

variable "env" {}

variable "profile" {
  type = string
}


variable "cluster_version" {
  type    = string
  default = "1.33"
}

variable "volume_size" {
  type    = string
  default = "50"
}

variable "volume_type"{
  type = string
  default = "gp3"
}

variable "architecture" {
  type    = string
  default = "x86_64"
}