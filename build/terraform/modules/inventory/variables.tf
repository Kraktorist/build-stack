variable ssh_user {
  type = string
  default = "ubuntu"
  description = "The user to connect to built machines"
}

# variable ssh_private_key_file {
#   type = string
#   default = "" # in case of empty value we use ./key file
#   description = "The SSH key to connect to built machines"
# }


variable ansible_inventory {
  type        = string
  default     = "inventory.yml"
  description = "Ansible inventory file which will be outputed"
}

variable instances {
  type        = list
  description = "List of Instances"
}

variable inventory {
  type        = map
  description = "Object of inventory"
}
