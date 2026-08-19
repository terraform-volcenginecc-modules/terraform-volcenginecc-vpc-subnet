output "subnet_ids" {
  description = "Map of stable logical keys to created subnet IDs."
  value = {
    for key, subnet in volcenginecc_vpc_subnet.this : key => subnet.subnet_id
  }
}

output "subnet_ids_by_type" {
  description = "Subnet IDs grouped by business classification. Classification does not configure routing or connectivity."
  value = {
    for subnet_type in ["public", "private", "database", "intra"] : subnet_type => toset([
      for key, subnet in volcenginecc_vpc_subnet.this : subnet.subnet_id
      if local.normalized_subnets[key].subnet_type == subnet_type
    ])
  }
}

output "subnet_ids_by_route_table_key" {
  description = "Subnet IDs grouped by the optional logical route_table_key for direct composition with the route-table module. This output does not create or own associations."
  value = {
    for route_table_key in toset([
      for subnet in values(local.normalized_subnets) : subnet.route_table_key
      if subnet.route_table_key != null
      ]) : route_table_key => toset([
      for key, subnet in volcenginecc_vpc_subnet.this : subnet.subnet_id
      if local.normalized_subnets[key].route_table_key == route_table_key
    ])
  }
}

output "subnet_route_table_keys" {
  description = "Map of subnet logical keys to desired route-table logical keys. These are composition hints, not cloud route-table IDs."
  value = {
    for key, subnet in local.normalized_subnets : key => subnet.route_table_key
    if subnet.route_table_key != null
  }
}

output "public_subnet_ids" {
  description = "IDs classified as public. A public classification alone does not provide internet connectivity."
  value = toset([
    for key, subnet in volcenginecc_vpc_subnet.this : subnet.subnet_id
    if local.normalized_subnets[key].subnet_type == "public"
  ])
}

output "private_subnet_ids" {
  description = "IDs classified as private. Actual isolation depends on route tables and network controls managed elsewhere."
  value = toset([
    for key, subnet in volcenginecc_vpc_subnet.this : subnet.subnet_id
    if local.normalized_subnets[key].subnet_type == "private"
  ])
}

output "database_subnet_ids" {
  description = "IDs classified as database subnets."
  value = toset([
    for key, subnet in volcenginecc_vpc_subnet.this : subnet.subnet_id
    if local.normalized_subnets[key].subnet_type == "database"
  ])
}

output "intra_subnet_ids" {
  description = "IDs classified as intra subnets."
  value = toset([
    for key, subnet in volcenginecc_vpc_subnet.this : subnet.subnet_id
    if local.normalized_subnets[key].subnet_type == "intra"
  ])
}

output "subnets" {
  description = "Stable subnet details for downstream route-table, compute, database, and load-balancer modules. Route-table fields are read-only diagnostics."
  value = {
    for key, subnet in volcenginecc_vpc_subnet.this : key => {
      id                         = subnet.subnet_id
      name                       = subnet.subnet_name
      cidr_block                 = subnet.cidr_block
      zone_id                    = subnet.zone_id
      subnet_type                = local.normalized_subnets[key].subnet_type
      desired_route_table_key    = local.normalized_subnets[key].route_table_key
      status                     = subnet.status
      available_ip_address_count = subnet.available_ip_address_count
      total_ipv4_count           = subnet.total_ipv_4_count
      ipv6_cidr_block            = subnet.read_ipv_6_cidr_block
      route_table_id             = try(subnet.route_table.route_table_id, null)
      route_table_type           = try(subnet.route_table.route_table_type, null)
      network_acl_id             = subnet.network_acl_id
      project_name               = subnet.project_name
      tags = subnet.tags == null ? tomap({}) : tomap({
        for tag in subnet.tags : tag.key => coalesce(tag.value, "")
      })
    }
  }
}
