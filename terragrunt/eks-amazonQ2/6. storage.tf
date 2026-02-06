# Encrypted Storage Class using AWS managed KMS
resource "kubernetes_storage_class_v1" "encrypted_gp3" {
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
    # AWS managed KMS key (no kmsKeyId specified)
    iops       = "3000"
    throughput = "125"
  }

  depends_on = [
    module.eks
  ]
}

# Remove default gp2 storage class
resource "kubectl_manifest" "remove_default_gp2" {
  yaml_body = <<-YAML
    apiVersion: storage.k8s.io/v1
    kind: StorageClass
    metadata:
      name: gp2
      annotations:
        storageclass.kubernetes.io/is-default-class: "false"
    provisioner: kubernetes.io/aws-ebs
    parameters:
      type: gp2
      fsType: ext4
    volumeBindingMode: WaitForFirstConsumer
  YAML

  depends_on = [
    kubernetes_storage_class_v1.encrypted_gp3
  ]
}
