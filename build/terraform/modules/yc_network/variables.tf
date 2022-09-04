variable network {
  type        = string
  default     = "lab-kubernetes"
  description = "Network name"
}

variable subnets {
  type        = map
  description = "Subnets For Instances"
}
