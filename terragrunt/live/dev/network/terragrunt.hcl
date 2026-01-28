include {
  path = find_in_parent_folders("root.hcl")
}

include "env" {
  path           = find_in_parent_folders("env.hcl")
  expose         = true
  merge_strategy = "no_merge"
}


terraform {
  source = "../../../modules/vpc"
}

inputs = {
  env                  = include.env.locals.env
  cidr_block    = "10.10.0.0/16"
  az_count      = 2
  enable_nat    = true         # enable NAT for private subnets
  single_nat_gw = true         # use single shared NAT (cost-effective)
}
