############################################
# TERRAFORM SETTINGS
############################################
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

############################################
# VARIABLES
############################################
variable "project_name" {
  type    = string
  default = "travelersources"
}

variable "dev_region" {
  type    = string
  default = "us-east-1"
}

variable "dr_region" {
  type    = string
  default = "us-west-2"
}

variable "dev_profile" {
  type = string
}

variable "dr_profile" {
  type = string
}

############################################
# PROVIDERS (MULTI-REGION)
############################################
provider "aws" {
  alias   = "dev"
  region  = var.dev_region
  profile = var.dev_profile
}

provider "aws" {
  alias   = "dr"
  region  = var.dr_region
  profile = var.dr_profile
}

############################################
# DEV BACKEND INFRA
############################################

# S3 Bucket
resource "aws_s3_bucket" "dev_tfstate" {
  provider = aws.dev
  bucket   = "${var.project_name}-tfstate-dev"

  tags = {
    Environment = "dev"
  }
}

# Versioning
resource "aws_s3_bucket_versioning" "dev_versioning" {
  provider = aws.dev
  bucket   = aws_s3_bucket.dev_tfstate.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "dev_encryption" {
  provider = aws.dev
  bucket   = aws_s3_bucket.dev_tfstate.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block Public Access
resource "aws_s3_bucket_public_access_block" "dev_block" {
  provider = aws.dev
  bucket   = aws_s3_bucket.dev_tfstate.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB Lock Table
resource "aws_dynamodb_table" "dev_locks" {
  provider     = aws.dev
  name         = "${var.project_name}-tf-locks-dev"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Environment = "dev"
  }
}

############################################
# DR BACKEND INFRA
############################################

# S3 Bucket
resource "aws_s3_bucket" "dr_tfstate" {
  provider = aws.dr
  bucket   = "${var.project_name}-tfstate-dr"

  tags = {
    Environment = "dr"
  }
}

# Versioning
resource "aws_s3_bucket_versioning" "dr_versioning" {
  provider = aws.dr
  bucket   = aws_s3_bucket.dr_tfstate.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "dr_encryption" {
  provider = aws.dr
  bucket   = aws_s3_bucket.dr_tfstate.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block Public Access
resource "aws_s3_bucket_public_access_block" "dr_block" {
  provider = aws.dr
  bucket   = aws_s3_bucket.dr_tfstate.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB Lock Table
resource "aws_dynamodb_table" "dr_locks" {
  provider     = aws.dr
  name         = "${var.project_name}-tf-locks-dr"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Environment = "dr"
  }
}
