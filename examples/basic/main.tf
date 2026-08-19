provider "volcenginecc" {
  region = var.region
}

module "subnets" {
  source  = "volcengine/vpc-subnet/volcenginecc"
  version = "~> 1.0"

  vpc_id      = var.vpc_id
  name_prefix = "example"

  subnets = {
    private-a = {
      cidr_block  = "10.10.1.0/24"
      zone_id     = var.zone_id
      subnet_type = "private"
    }
  }

  common_tags = {
    Environment = "example"
    ManagedBy   = "Terraform"
  }
}
