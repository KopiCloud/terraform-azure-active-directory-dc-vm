#####################################
## AD DC2 Virtual Machine - Output ##
#####################################

output "ad_dc2_vm_name" {
  description = "Domain Controller 1 Machine name"
  value       = azurerm_windows_virtual_machine.dc2-vm.name
}

output "ad_dc2_vm_ip_address" {
  description = "Domain Controller 1 IP Address"
  value       = azurerm_public_ip.dc2-eip.ip_address
}

/* output "ad_dc2_script_debug_1" {
 value = local.dc2_install_ad_1
}

output "ad_dc2_script_debug_2" {
 value = local.dc2_install_ad_2
}

output "ad_dc2_script_debug_3" {
 value = local.dc2_install_ad_3
}

output "ad_dc2_script_debug_4" {
 value = local.dc2_powershell_command
}

output "ad_dc2_script_debug_5" {
 value = local.dc2_credentials_1
}

output "ad_dc2_script_debug_6" {
 value = local.dc2_credentials_2
}

output "ad_dc2_script_debug_7" {
 value = local.dc2_credentials_3
} */

