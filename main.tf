# Controls for the terraform version allowed to be used from the cli.
/*
  Either your system needs to have this version of Terraform installed, or you 
  need to adjust this number to match the one you have on your system.
*/
terraform {
  required_version = ">= 0.12.29"
}

##################################################################################
# PROVIDERS
##################################################################################

provider "aws" {
  version    = "~> 2.66"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.region
}

provider "random" {
  version = "~> 2.2"
}

provider "template" {
  version = "~> 2.1"
}

##################################################################################
# DATA
##################################################################################

data "aws_availability_zones" "available" {}

/*
  In order to understand this template_file.public_cidrsubnet data {} object,
  You will need access to a particular video:
  Is will require a paid subscription.
  https://www.pluralsight.com
  Course = Terraform - Getting Started
  By = Ned Bellavance
  Module = 8
  Video = Using the VPC module
  Timestamp = 4 min 26 sec
*/
data "template_file" "public_cidrsubnet" {
  count = var.subnet_count[terraform.workspace]

  template = "$${cidrsubnet(vpc_cidr,8,current_count)}"

  vars = {
    vpc_cidr      = var.network_address_space[terraform.workspace]
    current_count = count.index
  }
}

##################################################################################
# RESOURCES
##################################################################################

#Random ID
resource "random_integer" "rand" {
  min = 10000
  max = 99999
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  # The dash turning blue is not a big deal.
  name    = "iss_track_phase_3-${local.env_name}-vpc"
  version = "2.44.0"

  cidr               = var.network_address_space[terraform.workspace]
  azs                = slice(data.aws_availability_zones.available.names, 0, var.subnet_count[terraform.workspace])
  public_subnets     = data.template_file.public_cidrsubnet[*].rendered # Expects CIDRs
  private_subnets    = []
  create_igw         = true
  enable_nat_gateway = true

  tags = local.common_tags
}
