variable "region" {
  description = "Volcengine region for the Provider."
  type        = string
  default     = "cn-beijing"
}

variable "vpc_id" {
  description = "ID of the existing VPC."
  type        = string
}

variable "zone_id" {
  description = "Availability zone ID for the subnet."
  type        = string
  default     = "cn-beijing-a"
}
