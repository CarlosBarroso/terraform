# networking
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name = "vpc-primary"
  cidr = var.vpc_cidr
  azs = slice(data.aws_availability_zones.available.names,0,var.subnet_count)
  private_subnets = var.private_subnets
  public_subnets = var.public_subnets
  
  enable_nat_gateway = true
  create_database_subnet_group = false
  
  tags = {
    Environment = "Production"
	  Team = "Network"
  }
}

output "private_subnets" {
    value = module.vpc.private_subnets
}

