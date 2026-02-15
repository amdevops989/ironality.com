############################################
# OUTPUTS
############################################

output "dev_s3_bucket_name" {
  value       = aws_s3_bucket.dev_tfstate.id
  description = "S3 bucket for Terraform state in DEV"
}

output "dev_dynamodb_table_name" {
  value       = aws_dynamodb_table.dev_locks.name
  description = "DynamoDB lock table for DEV"
}

output "dr_s3_bucket_name" {
  value       = aws_s3_bucket.dr_tfstate.id
  description = "S3 bucket for Terraform state in DR"
}

output "dr_dynamodb_table_name" {
  value       = aws_dynamodb_table.dr_locks.name
  description = "DynamoDB lock table for DR"
}