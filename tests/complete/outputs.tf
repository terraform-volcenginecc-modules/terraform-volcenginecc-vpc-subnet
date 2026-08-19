output "vpc_id" {
  description = "Fixture VPC ID."
  value       = volcenginecc_vpc_vpc.fixture.vpc_id
}

output "subnet_ids" {
  description = "Created Subnet IDs keyed by logical name."
  value       = module.subnets.subnet_ids
}

output "subnet_ids_by_type" {
  description = "Created Subnet IDs grouped by PRD classification."
  value       = module.subnets.subnet_ids_by_type
}

output "subnet_ids_by_route_table_key" {
  description = "Created Subnet IDs grouped by desired Route Table key."
  value       = module.subnets.subnet_ids_by_route_table_key
}

output "subnets" {
  description = "Created Subnet details used for real-cloud assertions."
  value       = module.subnets.subnets
}

output "route_table_ids" {
  description = "Created Route Table IDs keyed by logical name."
  value = {
    public   = volcenginecc_vpc_route_table.public.route_table_id
    private  = volcenginecc_vpc_route_table.private.route_table_id
    database = volcenginecc_vpc_route_table.database.route_table_id
  }
}

output "route_tables" {
  description = "Provider-read Route Table details used to verify actual Subnet associations."
  value = {
    public = {
      id         = volcenginecc_vpc_route_table.public.route_table_id
      subnet_ids = volcenginecc_vpc_route_table.public.subnet_ids
      vpc_id     = volcenginecc_vpc_route_table.public.vpc_id
    }
    private = {
      id         = volcenginecc_vpc_route_table.private.route_table_id
      subnet_ids = volcenginecc_vpc_route_table.private.subnet_ids
      vpc_id     = volcenginecc_vpc_route_table.private.vpc_id
    }
    database = {
      id         = volcenginecc_vpc_route_table.database.route_table_id
      subnet_ids = volcenginecc_vpc_route_table.database.subnet_ids
      vpc_id     = volcenginecc_vpc_route_table.database.vpc_id
    }
  }
}

output "subnet_route_table_ids" {
  description = "Expected mapping from each Subnet ID to its managed Route Table ID."
  value = merge(
    { for subnet_id in module.subnets.subnet_ids_by_route_table_key["public"] : subnet_id => volcenginecc_vpc_route_table.public.route_table_id },
    { for subnet_id in module.subnets.subnet_ids_by_route_table_key["private"] : subnet_id => volcenginecc_vpc_route_table.private.route_table_id },
    { for subnet_id in module.subnets.subnet_ids_by_route_table_key["database"] : subnet_id => volcenginecc_vpc_route_table.database.route_table_id }
  )
}

output "expected_subnets" {
  description = "Expected complete fixture attributes keyed by Subnet logical name."
  value = {
    for key, subnet in local.expected_subnets : key => merge(subnet, {
      name = "tf-subnet-complete-${var.run_id}-${key}"
      tags = {
        ManagedBy = "Terraform"
        TestRun   = var.run_id
        Tier      = subnet.subnet_type
      }
    })
  }
}
