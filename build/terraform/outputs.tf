# output "instances" {
#   # value       = module.yc_instance
#   value       = {for k, v in module.yc_instance: k => v.instances.network_interface[0].ip_address}
#   sensitive   = false
#   description = "List of Security Groups"
# }