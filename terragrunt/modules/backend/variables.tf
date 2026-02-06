variable "region" {
  description = "AWS region for the backend"
  type        = string
  default     = "us-east-1"
}

variable "profile" {
  description = "AWS CLI profile"
  type        = string
  default     = "dev-sso"
}

variable "bucket_name" {
  description = "S3 bucket name for Terraform state"
  type        = string
  default     = "travelersources-tfstate"
}

variable "lock_table_name" {
  description = "DynamoDB table name for Terraform locks"
  type        = string
  default     = "travelersources-tf-locks"
}

variable "kms_key_id" {
  description = "Customer-managed KMS key ID or ARN for S3 and DynamoDB encryption"
  type        = string
  default     = "arn:aws:kms:us-east-1:272495906318:key/54e3bb98-a1ee-4d8f-86cb-308fbbfc56c9"
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {
    Project     = "travelersources"
    Environment = "infra"
  }
}
