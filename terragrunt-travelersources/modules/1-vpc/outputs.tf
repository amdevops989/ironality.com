output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs (list)"
  value       = module.vpc.public_subnets
}

output "private_subnet_ids" {
  description = "Private subnet IDs (list)"
  value       = module.vpc.private_subnets
}

output "intra_subnet_ids" {
  description = "Private subnet IDs (list)"
  value       = module.vpc.intra_subnets
}

output "nat_gateway_ids" {
  description = "NAT Gateway IDs (list)"
  value       = module.vpc.natgw_ids
}
