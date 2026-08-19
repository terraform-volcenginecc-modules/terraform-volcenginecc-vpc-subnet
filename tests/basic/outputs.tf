output "vpc_id" {
  description = "Fixture VPC ID."
  value       = volcenginecc_vpc_vpc.fixture.vpc_id
}

output "subnet_ids" {
  description = "Created Subnet IDs keyed by logical name."
  value       = module.subnets.subnet_ids
}

output "subnets" {
  description = "Created Subnet details used for real-cloud assertions."
  value       = module.subnets.subnets
}

output "expected" {
  description = "Expected basic fixture attributes."
  value = {
    count = 1
    private-a = {
      cidr_block = "10.90.1.0/24"
      zone_id    = var.zone_id
      name       = "tf-subnet-basic-${var.run_id}-private-a"
      tags = {
        ManagedBy = "Terraform"
        TestRun   = var.run_id
        Tier      = "private"
      }
    }
  }
}
