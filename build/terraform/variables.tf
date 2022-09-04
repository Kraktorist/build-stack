variable config {
  type        = string
  default     = "hosts.yml"
  description = "List of machines to build"
}

variable ansible_inventory {
  type        = string
  default     = "inventory.yml"
  description = "Ansible inventory file which will be outputed"
}