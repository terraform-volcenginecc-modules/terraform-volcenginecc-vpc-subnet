output "vpc_id" {
  description = "Fixture VPC ID."
  value       = volcenginecc_vpc_vpc.fixture.vpc_id
}

output "subnet_ids" {
  description = "Created Subnet IDs."
  value       = module.subnets.subnet_ids
}

output "subnet_ids_by_route_table_key" {
  description = "Created Subnet IDs grouped for route-table composition."
  value       = module.subnets.subnet_ids_by_route_table_key
}

output "subnets" {
  description = "Created Subnet details."
  value       = module.subnets.subnets
}
