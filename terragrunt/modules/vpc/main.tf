terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

terraform {
  backend "s3" {}
}


data "aws_availability_zones" "available" {}

# --- VPC ---
resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = merge(local.common_tags, { Name = "${var.project_name}-${var.env}-vpc" })
}

# --- Internet Gateway ---
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = merge(local.common_tags, { Name = "${var.project_name}-${var.env}-igw" })
}

# --- Public Subnets ---
resource "aws_subnet" "public" {
  count                   = var.az_count
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.cidr_block, 8, count.index)
  map_public_ip_on_launch = true
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.env}-public-${count.index + 1}"
    Tier = "public"
    "kubernetes.io/role/elb"     = "1"
    "kubernetes.io/cluster/${var.project_name}-${var.env}" = "shared"
  })
}

# --- Private Subnets ---
resource "aws_subnet" "private" {
  count             = var.az_count
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.cidr_block, 8, count.index + var.az_count)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.env}-private-${count.index + 1}"
    Tier = "private"
    "kubernetes.io/role/internal-elb"    = "1"
    "kubernetes.io/cluster/${var.project_name}-${var.env}" = "shared"
  })
}

# --- NAT Gateway (optional + single/shared for cost) ---
resource "aws_eip" "nat" {
  count      = var.enable_nat ? (var.single_nat_gw ? 1 : var.az_count) : 0
  tags       = merge(local.common_tags, { Name = "${var.project_name}-${var.env}-nat-eip-${count.index + 1}" })
}



resource "aws_nat_gateway" "nat" {
  count         = var.enable_nat ? (var.single_nat_gw ? 1 : var.az_count) : 0
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index % var.az_count].id
  depends_on    = [aws_internet_gateway.igw]
  tags          = merge(local.common_tags, { Name = "${var.project_name}-${var.env}-nat-${count.index + 1}" })
}

# --- Route Tables ---
## Public
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = merge(local.common_tags, { Name = "${var.project_name}-${var.env}-public-rt" })
}

resource "aws_route_table_association" "public_assoc" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

## Private (only if NAT is enabled)
resource "aws_route_table" "private" {
  count  = var.enable_nat ? (var.single_nat_gw ? 1 : var.az_count) : 0
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.nat[*].id, count.index % length(aws_nat_gateway.nat))
  }
  tags = merge(local.common_tags, { Name = "${var.project_name}-${var.env}-private-rt-${count.index + 1}" })
}

resource "aws_route_table_association" "private_assoc" {
  count          = var.enable_nat ? length(aws_subnet.private) : 0
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = element(aws_route_table.private[*].id, count.index % length(aws_route_table.private))
}
