terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
  backend "s3" {
    bucket = "crossaccountpravalikabucket"
    key    = "3-Tier-Architectures/VPC-6-SUBNETS/terraform.state"
    region = "us-east-1"
  }
}

locals {
  prefix_name  = "vpc-6-subnets"
  environment  = "dev"
  region       = "us-east-1"
  create_vpc   = true
}

provider "aws" {
  region = local.region
}


##### Network Deployment #####
module "network" {
  source               = "./modules/networks/vpc_main"
  create_vpc           = local.create_vpc
  prefix_name          = local.prefix_name
  environment          = local.environment
  cidr                 = "10.8.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  vpc_tags = {
    "Name" = "${upper(local.prefix_name)}-${upper(local.environment)}"
  }


  subnets = [
    {
      "cidr"              = ["10.8.0.0/24", "10.8.1.0/24"]
      "isprivate"         = false
      "subnetType"        = "public"
      "subnetname_prefix" = "${local.prefix_name}-${local.environment}-public"
      "tags" = {
        "subnetType" = "public"
      }
    },
    {
      "cidr"              = ["10.8.3.0/24", "10.8.4.0/24"]
      "isprivate"         = true
      "subnetType"        = "database"
      "subnetname_prefix" = "${local.prefix_name}-${local.environment}-database-private"
      "tags" = {
        "subnetType" = "database"
      }
    },
    {
      "cidr"              = ["10.8.8.0/21", "10.8.16.0/21"]
      "isprivate"         = true
      "subnetType"        = "application"
      "subnetname_prefix" = "${local.prefix_name}-${local.environment}-app-private"
      "tags" = {
        "subnetType" = "application"
      }
    }
  ]
}

##### NACLs Rules #############################

module "PublicsubnetNaclRule" {
  source         = "./modules/networks/nacl_rules"
  vpc_id         = module.network.vpc_id
  network_acl_id = module.network.public_nacl_id.0
  ingress_rules = [
    ({
      egress     = false
      rule_no    = 100
      protocol   = "-1"
      from_port  = 0
      to_port    = 0
      cidr_block = "0.0.0.0/0"
      action     = "allow"
    })
  ]
  egress_rules = [
    ({
      egress     = true
      rule_no    = 100
      protocol   = "-1"
      from_port  = 0
      to_port    = 0
      cidr_block = "0.0.0.0/0"
      action     = "allow"
    })
  ]
}
module "DBsubnetNaclRule" {
  source         = "./modules/networks/nacl_rules"
  vpc_id         = module.network.vpc_id
  network_acl_id = module.network.db_nacl_id.0
  ingress_rules = [
    ({
      egress     = false
      rule_no    = 100
      protocol   = "-1"
      from_port  = 0
      to_port    = 0
      cidr_block = "0.0.0.0/0"
      action     = "allow"
    })
  ]
  egress_rules = [
    ({
      egress = true

      rule_no    = 100
      protocol   = "-1"
      from_port  = 0
      to_port    = 0
      cidr_block = "0.0.0.0/0"
      action     = "allow"
    })
  ]
}

module "appsubnetNaclRule" {
  source         = "./modules/networks/nacl_rules"
  vpc_id         = module.network.vpc_id
  network_acl_id = module.network.app_nacl_id.0
  ingress_rules = [
    ({
      egress     = false
      rule_no    = 100
      protocol   = "-1"
      from_port  = 0
      to_port    = 0
      cidr_block = "0.0.0.0/0"
      action     = "allow"
    })
  ]
  egress_rules = [
    ({
      egress = true

      rule_no    = 100
      protocol   = "-1"
      from_port  = 0
      to_port    = 0
      cidr_block = "0.0.0.0/0"
      action     = "allow"
    })
  ]
}


####### Outputs #######

output "vpc_id" {
  value = module.network.*.vpc_id
}
output "databaseSubnetIds" {
  value = module.network.*.databaseSubnetIds
}
output "applicationSubnetIds" {
  value = module.network.*.applicationSubnetIds
}
output "publicSubnetIds" {
  value = module.network.*.publicSubnetIds
}

#######################
