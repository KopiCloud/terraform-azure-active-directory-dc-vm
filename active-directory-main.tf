#############################
## Active Directory - Main ##
#############################

# Locals
locals {
  dns_servers = [ var.ad_dc1_ip_address, var.ad_dc2_ip_address ]
  dc_servers = [ var.ad_dc1_ip_address, var.ad_dc2_ip_address ]
}

# Create an availability set for domain controllers
resource "azurerm_availability_set" "dc-availability-set" {
  name                         = "dc-availability-set-${var.environment}"
  resource_group_name          = azurerm_resource_group.network-rg.name
  location                     = azurerm_resource_group.network-rg.location
  platform_fault_domain_count  = 3
  platform_update_domain_count = 5
  managed                      = true
}

output "ad_domain_controllers_list_ip_address" {
  description = "List of Domain Controller IP Address"
  value       = local.dns_servers
}

output "ad_domain_controllers_count" {
  description = "List of Domain Controller IP Address"
  value       = length(local.dns_servers)
}