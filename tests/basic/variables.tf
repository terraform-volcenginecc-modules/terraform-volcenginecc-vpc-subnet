variable "region" {
  description = "Region used by the basic real-cloud fixture."
  type        = string
  default     = "cn-beijing"
}

variable "zone_id" {
  description = "Availability zone used by the basic real-cloud fixture."
  type        = string
  default     = "cn-beijing-a"
}

variable "run_id" {
  description = "Unique suffix for real-cloud resources."
  type        = string
  nullable    = false

  validation {
    condition     = trimspace(var.run_id) != ""
    error_message = "run_id must be non-empty."
  }
}
