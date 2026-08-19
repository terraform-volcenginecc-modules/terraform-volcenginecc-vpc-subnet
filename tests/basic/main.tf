provider "volcenginecc" {
  region = var.region
}

resource "volcenginecc_vpc_vpc" "fixture" {
  vpc_name   = "tf-subnet-basic-${var.run_id}"
  cidr_block = "10.90.0.0/16"

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
  name_prefix = "tf-subnet-basic-${var.run_id}"

  subnets = {
    private-a = {
      cidr_block  = "10.90.1.0/24"
      zone_id     = var.zone_id
      subnet_type = "private"
      tags = {
        Tier = "private"
      }
    }
  }

  common_tags = {
    ManagedBy = "Terraform"
    TestRun   = var.run_id
  }
}
