variable "pangolin_endpoint" {
  description = "Pangolin endpoint for the newt container."
  type        = string
  default     = ""
}

variable "newt_secret" {
  description = "Secret used by the newt container (set via tfvars or CI)."
  type        = string
  sensitive   = true
  default     = ""
}

variable "newt_id" {
  description = "ID for the newt container instance."
  type        = string
  default     = ""
}
