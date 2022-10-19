variable ssh_user {
  type = string
  default = "ubuntu"
  description = "The user to connect to built machines"
}

variable ssh_private_key_file {
  type = string
  default = "~/ya_key.pub"
  description = "The SSH key to connect to built machines"
}

variable os_family {
  type        = string
  default     = "ubuntu-2004-lts"
  description = "Operating System family"
}

variable node {
  type = object({
      name = string
      cpu = number
      memory = number
      disk = number
      subnet = string
      public_ip = string
      security_groups = list(string)
  })
  description = "Instance Parameters"
}

variable subnets {
  type        = map
  description = "List of Subnets"
}

variable security_groups {
  type        = map
  description = "List of Security Groups"
}


variable ENV {
  type        = string
  default     = ""
  description = "environment label"
}
