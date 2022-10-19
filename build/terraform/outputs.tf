# output "instances" {
#   value       = {for k, v in module.yc_instance: k => v.instances.network_interface[0].ip_address}
#   sensitive   = false
#   description = "List of Security Groups"
# }

# output "security_groups" {
#   value       = [for k, v in module.yc_network[0].security_groups: v.name]
#   sensitive   = false
#   description = "List of Security Groups"
# }