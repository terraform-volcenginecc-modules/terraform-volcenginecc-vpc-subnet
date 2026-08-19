provider "volcenginecc" {
  region = var.region
}

module "subnets" {
  source  = "volcengine/vpc-subnet/volcenginecc"
  version = "~> 1.0"

  vpc_id      = var.vpc_id
  name_prefix = "application"

  subnets = {
    public-a = {
      cidr_block      = "10.10.1.0/24"
      zone_id         = var.zone_ids.primary
      subnet_type     = "public"
      route_table_key = "public"
    }
    public-b = {
      cidr_block      = "10.10.2.0/24"
      zone_id         = var.zone_ids.secondary
      subnet_type     = "public"
      route_table_key = "public"
    }
    private-a = {
      cidr_block      = "10.10.11.0/24"
      zone_id         = var.zone_ids.primary
      subnet_type     = "private"
      route_table_key = "private"
    }
    private-b = {
      cidr_block      = "10.10.12.0/24"
      zone_id         = var.zone_ids.secondary
      subnet_type     = "private"
      route_table_key = "private"
    }
    database-a = {
      cidr_block      = "10.10.21.0/24"
      zone_id         = var.zone_ids.primary
      subnet_type     = "database"
      route_table_key = "database"
      tags = {
        Workload = "database"
      }
    }
    intra-a = {
      cidr_block      = "10.10.31.0/24"
      zone_id         = var.zone_ids.primary
      subnet_type     = "intra"
      route_table_key = "intra"
      description     = "Internal service subnet"
    }
  }

  common_tags = {
    Environment = "example"
    ManagedBy   = "Terraform"
  }
}
