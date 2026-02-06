# EBS CSI Driver Add-on
resource "aws_eks_addon" "ebs_csi" {
  cluster_name             = var.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = "v1.35.0-eksbuild.1" # Use latest available version
  service_account_role_arn = aws_iam_role.ebs_csi_driver.arn
  
  tags = {
    Name = "${var.cluster_name}-ebs-csi-driver"
  }

  depends_on = [
    aws_eks_node_group.main
  ]
}


# Storage Class with KMS encryption
resource "kubernetes_storage_class" "encrypted_gp3" {
  metadata {
    name = "encrypted-gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy        = "Delete"
  volume_binding_mode   = "WaitForFirstConsumer"
  allow_volume_expansion = true

  parameters = {
    type      = "gp3"
    encrypted = "true"
    kmsKeyId  = var.kms_key_arn  # Your existing KMS key
    fsType    = "ext4"
    iops      = "3000"
    throughput = "125"
  }
}

# # Optional: Remove default storage class annotation from gp2
# resource "kubernetes_annotations" "default_storageclass" {
#   api_version = "storage.k8s.io/v1"
#   kind        = "StorageClass"
#   metadata {
#     name = "gp2"
#   }
#   annotations = {
#     "storageclass.kubernetes.io/is-default-class" = "false"
#   }

#   depends_on = [aws_eks_addon.ebs_csi]
# }

# Data sources


# # Variables (add these to your variables.tf)
# variable "kms_key_arn" {
#   description = "ARN of the KMS key for EBS encryption"
#   type        = string
# }

