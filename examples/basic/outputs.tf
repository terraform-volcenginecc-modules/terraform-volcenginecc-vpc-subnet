output "subnet_ids" {
  description = "Created subnet IDs keyed by logical name."
  value       = module.subnets.subnet_ids
}
