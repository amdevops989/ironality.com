variable "region" {
  description = "AWS region for the backend"
  type        = string
  default     = "us-east-1"
}

variable "profile" {
  description = "AWS CLI profile"
  type        = string
  default     = "devops-am"
}

variable "bucket_name" {
  description = "S3 bucket name for Terraform state"
  type        = string
}

variable "lock_table_name" {
  description = "DynamoDB table name for Terraform locks"
  type        = string
}

variable "kms_key_id" {
  description = "Customer-managed KMS key ID or ARN for S3 and DynamoDB encryption"
  type        = string
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
