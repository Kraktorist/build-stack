variable domains {
  type        = list
  description = "List of Domains for Let's Encrypt Certificate"
}

variable name {
  type        = string
  description = "Certificate Name"
}

variable wait_validation {
  type        = bool
  default     = true
  description = "Check for Validation Status of Certificate"
}


variable ENV {
  type        = string
  default     = ""
  description = "environment label"
}
