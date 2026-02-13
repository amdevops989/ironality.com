# -------------------------------------
# EKS Node IAM Role
# -------------------------------------
resource "aws_iam_role" "eks_node_role" {
  name = "${var.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  tags = {
    TerraformManaged = "true"
  }
}

# Standard Node Policies
resource "aws_iam_role_policy_attachment" "worker_node_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "cni_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "ecr_readonly" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# KMS Policy for Node Root + PVC Volumes
resource "aws_iam_policy" "eks_node_kms_policy" {
  name   = "${var.cluster_name}-node-kms"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey",
        "kms:CreateGrant"  # ✅ required for PVC attach
      ]
      Resource = var.kms_key_arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_node_kms_attach" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = aws_iam_policy.eks_node_kms_policy.arn
}

# aws ssm get-parameter \
#   --name /aws/service/eks/optimized-ami/1.30/amazon-linux-2023/x86_64/standard/recommended/image_id \
#   --region us-east-1

data "aws_ssm_parameter" "eks_worker_ami_al2023" {
  name = "/aws/service/eks/optimized-ami/${var.cluster_version}/amazon-linux-2023/x86_64/standard/recommended/image_id"
}

# -------------------------------------
# Instance Profile
# -------------------------------------
resource "aws_iam_instance_profile" "eks_node_profile" {
  name = "${var.cluster_name}-node-profile"
  role = aws_iam_role.eks_node_role.name
}


# -------------------------------------
# Launch Template (gp3 + KMS root volume)
# -------------------------------------
resource "aws_launch_template" "eks_nodes" {
  name_prefix   = "${var.cluster_name}-lt-"
  image_id      = data.aws_ssm_parameter.eks_worker_ami_al2023.value
  instance_type = var.node_instance_type

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = var.volume_size
      volume_type = var.volume_type
      encrypted   = true
      kms_key_id  = var.kms_key_arn
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, { Name = "${var.cluster_name}-node" })
  }
}


# -------------------------------------
# Managed Node Group using Launch Template
# -------------------------------------
resource "aws_eks_node_group" "default" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-ng"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = var.private_subnets

  scaling_config {
    desired_size = var.node_desired_capacity
    min_size     = var.node_min_capacity
    max_size     = var.node_max_capacity
  }

  capacity_type = "ON_DEMAND"

  launch_template {
    id      = aws_launch_template.eks_nodes.id
    version = "$Latest"
  }

  tags = merge(var.tags, { Name = "${var.cluster_name}-node" })

  update_config {
    max_unavailable = 1
  }

  labels = {
    role = "general"
  }

  depends_on = [
    aws_iam_role_policy_attachment.worker_node_policy,
    aws_iam_role_policy_attachment.cni_policy,
    aws_iam_role_policy_attachment.ecr_readonly,
    aws_iam_role_policy_attachment.eks_node_kms_attach
  ]

  ## allow external changes without  Terraform plan difference
  lifecycle {
    ignore_changes  = [scaling_config[0].desired_size]
  }
}

