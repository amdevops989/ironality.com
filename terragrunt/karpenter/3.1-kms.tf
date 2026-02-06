# ###############################################################################
# # KMS
# ###############################################################################
# module "kms" {
#   source  = "terraform-aws-modules/kms/aws"
#   version = "3.1.0"

#   description = "EKS Cluster"
#   key_usage   = "ENCRYPT_DECRYPT"

#   # Policy
#   key_administrators                 = [data.aws_caller_identity.current.arn]
#   key_owners                         = [data.aws_caller_identity.current.arn]
#   key_service_roles_for_autoscaling  = ["arn:aws:iam::${var.aws_account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"]

#   # Aliases
#   aliases = ["eks/${var.app_name}"]

#   tags = {
#     Terraform   = "true"
#     Environment = var.environment
#   }
# }