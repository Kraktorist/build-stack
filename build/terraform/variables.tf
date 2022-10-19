variable config {
  type        = string
  default     = "../config.yml"
  description = "List of machines to build"
}

variable ansible_inventory {
  type        = string
  default     = "inventory.yml"
  description = "Ansible inventory file which will be outputed"
}

variable ENV {
  type        = string
  default     = ""
  description = "environment label"
}
