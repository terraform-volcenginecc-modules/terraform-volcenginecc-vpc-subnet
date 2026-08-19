locals {
  normalized_subnets = {
    for key, subnet in var.subnets : key => {
      cidr_block      = subnet.cidr_block
      zone_id         = subnet.zone_id
      subnet_type     = subnet.subnet_type
      route_table_key = subnet.route_table_key
      subnet_name     = coalesce(subnet.name, var.name_prefix == null ? key : "${var.name_prefix}-${key}")
      description     = subnet.description
      tags            = merge(var.common_tags, subnet.tags)
    }
  }
}

resource "volcenginecc_vpc_subnet" "this" {
  for_each = local.normalized_subnets

  vpc_id      = var.vpc_id
  cidr_block  = each.value.cidr_block
  zone_id     = each.value.zone_id
  subnet_name = each.value.subnet_name
  description = each.value.description
  tags = length(each.value.tags) == 0 ? null : [
    for key in sort(keys(each.value.tags)) : {
      key   = key
      value = each.value.tags[key]
    }
  ]

  lifecycle {
    precondition {
      condition = (
        length(each.value.subnet_name) >= 1 &&
        length(each.value.subnet_name) <= 128 &&
        can(regex("^[\\p{L}\\p{N}][\\p{L}\\p{N}._-]*$", each.value.subnet_name))
      )
      error_message = "The generated subnet name must contain 1 to 128 supported characters and start with a letter or number."
    }
  }
}
