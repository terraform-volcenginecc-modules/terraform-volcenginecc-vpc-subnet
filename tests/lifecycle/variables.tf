variable "region" {
  description = "Region used by the real-cloud lifecycle fixture."
  type        = string
  default     = "cn-beijing"
}

variable "zone_ids" {
  description = "Availability zones used by the fixture."
  type = object({
    primary   = string
    secondary = string
  })
  default = {
    primary   = "cn-beijing-a"
    secondary = "cn-beijing-b"
  }
}

variable "run_id" {
  description = "Unique suffix for real-cloud resources."
  type        = string
}

variable "phase" {
  description = "Lifecycle phase: create or update."
  type        = string
  default     = "create"

  validation {
    condition     = contains(["create", "update"], var.phase)
    error_message = "phase must be create or update."
  }
}
