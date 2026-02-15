include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

include "env" {
  path           = find_in_parent_folders("env.hcl")
  expose         = true
  merge_strategy = "no_merge"
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    vpc_id          = "vpc-123456"
    vpc_cidr_block  = "10.0.0.0/16"
    private_subnet_ids = ["subnet-c","subnet-d"]
  }
  mock_outputs_merge_with_state = true
}

locals {
  cluster_name = "${include.root.locals.project_name}-${include.env.locals.env}"
}

terraform {
  source = "../../../modules/11-rds"
}

inputs = {
  cluster_name         = local.cluster_name
  region               = include.root.locals.aws_region
  profile              = include.root.locals.aws_profile
  env                  = include.env.locals.env
  project_name         = include.root.locals.project_name
  vpc_cidr_block       = dependency.vpc.outputs.vpc_cidr_block
  vpc_id               = dependency.vpc.outputs.vpc_id
  private_subnets      = dependency.vpc.outputs.private_subnet_ids
  tags = {
    Project     = include.root.locals.project_name
    Environment = include.env.locals.env
  }


}
