variable "vpc_id" {
  description = "ID of the existing VPC in which to create the subnets."
  type        = string
  nullable    = false

  validation {
    condition     = trimspace(var.vpc_id) != ""
    error_message = "vpc_id must be a non-empty VPC ID."
  }
}

variable "name_prefix" {
  description = "Optional prefix used when a subnet does not provide an explicit name. The map key is appended as the stable suffix."
  type        = string
  default     = null

  validation {
    condition     = var.name_prefix == null || (trimspace(var.name_prefix) != "" && length(var.name_prefix) <= 128)
    error_message = "name_prefix must be null or a non-empty string no longer than 128 characters."
  }

  validation {
    condition     = var.name_prefix == null || can(regex("^[\\p{L}\\p{N}][\\p{L}\\p{N}._-]*$", var.name_prefix))
    error_message = "name_prefix must start with a letter or number and contain only letters, numbers, periods, underscores, and hyphens."
  }
}

variable "common_tags" {
  description = "Tags applied to every subnet. Per-subnet tags override matching keys."
  type        = map(string)
  default     = {}
  nullable    = false

  validation {
    condition = alltrue([
      for key in keys(var.common_tags) : trimspace(key) != ""
    ])
    error_message = "common_tags keys must not be empty."
  }
}

variable "subnets" {
  description = "Subnets keyed by a stable logical name. subnet_type classifies the intended network tier; route_table_key groups subnet IDs for composition with the route-table module. Neither field configures routing or internet connectivity by itself."
  type = map(object({
    cidr_block      = string
    zone_id         = string
    subnet_type     = optional(string, "private")
    route_table_key = optional(string)
    name            = optional(string)
    description     = optional(string)
    tags            = optional(map(string), {})
  }))
  nullable = false

  validation {
    condition     = length(var.subnets) > 0
    error_message = "subnets must contain at least one subnet."
  }

  validation {
    condition = alltrue([
      for subnet in values(var.subnets) : trimspace(subnet.zone_id) != ""
    ])
    error_message = "Every subnet must provide a non-empty availability zone ID."
  }

  validation {
    condition = alltrue([
      for subnet in values(var.subnets) : contains(["public", "private", "database", "intra"], subnet.subnet_type)
    ])
    error_message = "subnet_type must be public, private, database, or intra."
  }

  validation {
    condition = alltrue([
      for subnet in values(var.subnets) : subnet.route_table_key == null || (
        trimspace(subnet.route_table_key) != "" &&
        can(regex("^[A-Za-z0-9][A-Za-z0-9._-]*$", subnet.route_table_key))
      )
    ])
    error_message = "route_table_key must be null or a non-empty logical key containing only letters, numbers, periods, underscores, and hyphens."
  }

  validation {
    condition = alltrue([
      for subnet in values(var.subnets) : can(cidrnetmask(subnet.cidr_block))
    ])
    error_message = "Every cidr_block must be a valid IPv4 CIDR."
  }

  validation {
    condition = alltrue([
      for subnet in values(var.subnets) : try(
        cidrhost(subnet.cidr_block, 0) == split("/", subnet.cidr_block)[0] &&
        (
          tonumber(split(".", cidrhost(subnet.cidr_block, 0))[0]) == 10 ||
          (
            tonumber(split(".", cidrhost(subnet.cidr_block, 0))[0]) == 172 &&
            tonumber(split(".", cidrhost(subnet.cidr_block, 0))[1]) >= 16 &&
            tonumber(split(".", cidrhost(subnet.cidr_block, 0))[1]) <= 31
          ) ||
          (
            tonumber(split(".", cidrhost(subnet.cidr_block, 0))[0]) == 192 &&
            tonumber(split(".", cidrhost(subnet.cidr_block, 0))[1]) == 168
          )
        ),
        false
      )
    ])
    error_message = "Every cidr_block must be a canonical private IPv4 network in 10.0.0.0/8, 172.16.0.0/12, or 192.168.0.0/16."
  }

  validation {
    condition = alltrue([
      for subnet in values(var.subnets) : subnet.name == null || (
        length(subnet.name) >= 1 &&
        length(subnet.name) <= 128 &&
        can(regex("^[\\p{L}\\p{N}][\\p{L}\\p{N}._-]*$", subnet.name))
      )
    ])
    error_message = "Each explicit subnet name must contain 1 to 128 supported characters and start with a letter or number."
  }

  validation {
    condition = alltrue([
      for subnet in values(var.subnets) : subnet.description == null || (
        length(subnet.description) <= 255 &&
        (
          subnet.description == "" ||
          can(regex("^[\\p{L}\\p{N}][\\p{L}\\p{N},._ =\\-，。]*$", subnet.description))
        )
      )
    ])
    error_message = "Each description must be empty or contain at most 255 supported characters; URL prefixes are not allowed."
  }

  validation {
    condition = alltrue(flatten([
      for subnet in values(var.subnets) : [
        for key in keys(subnet.tags) : trimspace(key) != ""
      ]
    ]))
    error_message = "Per-subnet tag keys must not be empty."
  }
}
