terraform {
  source = "../../modules/backend"
}

inputs = {
  bucket_name      = "travelersources-tfstate"
  lock_table_name  = "travelersources-tf-locks"
  region           = "us-east-1"
  profile          = "devops-am"
  kms_key_id       = "arn:aws:kms:us-east-1:272495906318:key/54e3bb98-a1ee-4d8f-86cb-308fbbfc56c9"  # <-- replace with your CMK ARN
  tags = {
    Project     = "travelersources"
    Environment = "infra"
  }
}
