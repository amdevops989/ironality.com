# # networking-tags.tf

# resource "aws_ec2_tag" "private_subnet_karpenter_discovery" {
#   count       = length(aws_subnet.private)
#   resource_id = aws_subnet.private[count.index].id
#   key   = "karpenter.sh/discovery"
#   value = var.cluster_name
#   depends_on = [aws_vpc.main]
  
# }

# resource "aws_ec2_tag" "node_security_group_karpenter_discovery" {
#   resource_id = aws_security_group.node_group.id
#   key         = "karpenter.sh/discovery"
#   value       = var.cluster_name
#   depends_on = [aws_security_group.node_group]
# }

# resource "aws_ec2_tag" "cluster_security_group_karpenter_discovery" {
#   resource_id = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
#   key         = "karpenter.sh/discovery"
#   value       = var.cluster_name
#   depends_on = [aws_eks_cluster.main]
# }
