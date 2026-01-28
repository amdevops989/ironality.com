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
  config_path = "../network"
  mock_outputs = {
    vpc_id          = "vpc-123456"
    public_subnets  = ["subnet-a","subnet-b"]
    private_subnets = ["subnet-c","subnet-d"]
  }
  mock_outputs_merge_with_state = true
}

locals {
  cluster_name = "${include.root.locals.project_name}-${include.env.locals.env}"
}

terraform {
  source = "../../../modules/eks"
}

inputs = {
  cluster_name         = local.cluster_name
  region               = include.root.locals.aws_region
  profile              = include.root.locals.aws_profile
  env                  = include.env.locals.env
  project_name         = include.root.locals.project_name

  vpc_id               = dependency.vpc.outputs.vpc_id
  private_subnets      = dependency.vpc.outputs.private_subnets

  node_instance_type   = "t3.large"    # spot mode for dev and test
  node_desired_capacity = 1
  node_min_capacity     = 1
  node_max_capacity     = 1
  ssh_key_name          = ""
  kms_key_id            = "arn:aws:kms:us-east-1:272495906318:key/54e3bb98-a1ee-4d8f-86cb-308fbbfc56c9"

  tags = {
    Project     = include.root.locals.project_name
    Environment = include.env.locals.env
  }
}
