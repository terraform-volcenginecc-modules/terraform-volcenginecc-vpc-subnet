variable "region" {
  description = "Region used by the complete real-cloud fixture."
  type        = string
  default     = "cn-beijing"
}

variable "zone_ids" {
  description = "Two availability zones used by the complete real-cloud fixture."
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
  nullable    = false

  validation {
    condition     = trimspace(var.run_id) != ""
    error_message = "run_id must be non-empty."
  }
}
