resource "aws_launch_template" "eks_nodes" {
  name_prefix   = "eks-self-managed-"
  image_id      = data.aws_ami.eks_worker.id
  instance_type = "m5.large"
  key_name      = var.key_pair_name

  vpc_security_group_ids = [aws_security_group.eks_nodes.id]

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 50
      volume_type = "gp3"
      encrypted   = true
      kms_key_id  = aws_kms_key.eks_encryption.arn
      delete_on_termination = true
    }
  }

  user_data = base64encode(templatefile("${path.module}/userdata.sh", {
    cluster_name = aws_eks_cluster.main.name
    endpoint     = aws_eks_cluster.main.endpoint
    ca_data      = aws_eks_cluster.main.certificate_authority[0].data
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "eks-self-managed-node"
      "kubernetes.io/cluster/${aws_eks_cluster.main.name}" = "owned"
    }
  }
}

resource "aws_autoscaling_group" "eks_nodes" {
  name                = "eks-self-managed-nodes"
  vpc_zone_identifier = var.subnet_ids
  target_group_arns   = []
  health_check_type   = "EC2"
  
  min_size         = 1
  max_size         = 4
  desired_capacity = 2

  launch_template {
    id      = aws_launch_template.eks_nodes.id
    version = "$Latest"
  }

  tag {
    key                 = "kubernetes.io/cluster/${aws_eks_cluster.main.name}"
    value               = "owned"
    propagate_at_launch = true
  }
}
