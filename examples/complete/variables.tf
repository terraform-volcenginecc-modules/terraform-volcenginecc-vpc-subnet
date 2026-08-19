variable "region" {
  description = "Volcengine region for the Provider."
  type        = string
  default     = "cn-beijing"
}

variable "vpc_id" {
  description = "ID of the existing VPC."
  type        = string
}

variable "zone_ids" {
  description = "Availability zones used by the example."
  type = object({
    primary   = string
    secondary = string
  })
  default = {
    primary   = "cn-beijing-a"
    secondary = "cn-beijing-b"
  }
}
