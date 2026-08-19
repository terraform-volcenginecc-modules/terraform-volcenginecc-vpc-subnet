provider "volcenginecc" {
  region = var.region
}

locals {
  is_update = var.phase == "update"
}

resource "volcenginecc_vpc_vpc" "fixture" {
  vpc_name   = "tf-subnet-${var.run_id}"
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
  name_prefix = "tf-subnet-${var.run_id}"

  subnets = merge(
    {
      private-a = {
        cidr_block      = "10.91.1.0/24"
        zone_id         = var.zone_ids.primary
        subnet_type     = "private"
        route_table_key = "private"
        name            = local.is_update ? "tf-subnet-${var.run_id}-private-a-updated" : null
        description     = local.is_update ? "Updated private subnet" : "Initial private subnet"
      }
    },
    local.is_update ? {
      database-b = {
        cidr_block      = "10.91.2.0/24"
        zone_id         = var.zone_ids.secondary
        subnet_type     = "database"
        route_table_key = "database"
        description     = "Added during update"
      }
    } : {}
  )

  common_tags = {
    ManagedBy = "Terraform"
    TestRun   = var.run_id
    Phase     = var.phase
  }
}
