output "subnet_ids" {
  description = "All created subnet IDs keyed by logical name."
  value       = module.subnets.subnet_ids
}

output "subnet_ids_by_type" {
  description = "Created subnet IDs grouped by business classification."
  value       = module.subnets.subnet_ids_by_type
}

output "subnet_ids_by_route_table_key" {
  description = "Created subnet IDs grouped for downstream route-table association."
  value       = module.subnets.subnet_ids_by_route_table_key
}
