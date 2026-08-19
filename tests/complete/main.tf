provider "volcenginecc" {
  region = var.region
}

locals {
  expected_subnets = {
    public-a = {
      cidr_block      = "10.91.1.0/24"
      zone_id         = var.zone_ids.primary
      subnet_type     = "public"
      route_table_key = "public"
    }
    public-b = {
      cidr_block      = "10.91.2.0/24"
      zone_id         = var.zone_ids.secondary
      subnet_type     = "public"
      route_table_key = "public"
    }
    private-a = {
      cidr_block      = "10.91.11.0/24"
      zone_id         = var.zone_ids.primary
      subnet_type     = "private"
      route_table_key = "private"
    }
    private-b = {
      cidr_block      = "10.91.12.0/24"
      zone_id         = var.zone_ids.secondary
      subnet_type     = "private"
      route_table_key = "private"
    }
    database-a = {
      cidr_block      = "10.91.21.0/24"
      zone_id         = var.zone_ids.primary
      subnet_type     = "database"
      route_table_key = "database"
    }
    database-b = {
      cidr_block      = "10.91.22.0/24"
      zone_id         = var.zone_ids.secondary
      subnet_type     = "database"
      route_table_key = "database"
    }
  }

  route_table_tags = [
    {
      key   = "ManagedBy"
      value = "Terraform"
    },
    {
      key   = "TestRun"
      value = var.run_id
    }
  ]
}

resource "volcenginecc_vpc_vpc" "fixture" {
  vpc_name   = "tf-subnet-complete-${var.run_id}"
  cidr_block = "10.91.0.0/16"

  tags = [
    {
      key   = "TestRun"
      value = var.run_id
    }
  ]
}

module "subnets" {
  source = "../.."

  vpc_id      = volcenginecc_vpc_vpc.fixture.vpc_id
  name_prefix = "tf-subnet-complete-${var.run_id}"
  subnets = {
    for key, subnet in local.expected_subnets : key => merge(subnet, {
      tags = {
        Tier = subnet.subnet_type
      }
    })
  }

  common_tags = {
    ManagedBy = "Terraform"
    TestRun   = var.run_id
  }
}

resource "volcenginecc_vpc_route_table" "public" {
  vpc_id           = volcenginecc_vpc_vpc.fixture.vpc_id
  associate_type   = "Subnet"
  route_table_name = "tf-subnet-${var.run_id}-public"
  description      = "Subnet validation public route table"
  subnet_ids       = module.subnets.subnet_ids_by_route_table_key["public"]
  tags             = local.route_table_tags
}

resource "volcenginecc_vpc_route_table" "private" {
  vpc_id           = volcenginecc_vpc_vpc.fixture.vpc_id
  associate_type   = "Subnet"
  route_table_name = "tf-subnet-${var.run_id}-private"
  description      = "Subnet validation private route table"
  subnet_ids       = module.subnets.subnet_ids_by_route_table_key["private"]
  tags             = local.route_table_tags

  depends_on = [volcenginecc_vpc_route_table.public]
}

resource "volcenginecc_vpc_route_table" "database" {
  vpc_id           = volcenginecc_vpc_vpc.fixture.vpc_id
  associate_type   = "Subnet"
  route_table_name = "tf-subnet-${var.run_id}-database"
  description      = "Subnet validation database route table"
  subnet_ids       = module.subnets.subnet_ids_by_route_table_key["database"]
  tags             = local.route_table_tags

  depends_on = [volcenginecc_vpc_route_table.private]
}
