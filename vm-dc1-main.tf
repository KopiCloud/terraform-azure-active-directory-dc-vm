###################################
## AD DC1 Virtual Machine - Main ##
###################################

# Local variables
locals {
  dc1_fqdn = "${var.ad_dc1_name}.${var.ad_domain_name}"
  
  dc1_prereq_ad_1 = "Import-Module ServerManager"
  dc1_prereq_ad_2 = "Install-WindowsFeature AD-Domain-Services -IncludeAllSubFeature -IncludeManagementTools"
  dc1_prereq_ad_3 = "Install-WindowsFeature DNS -IncludeAllSubFeature -IncludeManagementTools"
  dc1_prereq_ad_4 = "Import-Module ADDSDeployment"
  dc1_prereq_ad_5 = "Import-Module DnsServer"

  dc1_install_ad_1 = "Install-ADDSForest -DomainName ${var.ad_domain_name} -DomainNetbiosName ${var.ad_domain_netbios_name} -DomainMode ${var.ad_domain_mode} -ForestMode ${var.ad_domain_mode} "
  dc1_install_ad_2 = "-DatabasePath ${var.ad_database_path} -SysvolPath ${var.ad_sysvol_path} -LogPath ${var.ad_log_path} -NoRebootOnCompletion:$false -Force:$true "
  dc1_install_ad_3 = "-SafeModeAdministratorPassword (ConvertTo-SecureString ${var.ad_safe_mode_administrator_password} -AsPlainText -Force)"
  
  dc1_shutdown_command   = "shutdown -r -t 10"
  dc1_exit_code_hack     = "exit 0"
  dc1_powershell_command = "${local.dc1_prereq_ad_1}; ${local.dc1_prereq_ad_2}; ${local.dc1_prereq_ad_3}; ${local.dc1_prereq_ad_4}; ${local.dc1_prereq_ad_5}; ${local.dc1_install_ad_1}${local.dc1_install_ad_2}${local.dc1_install_ad_3}; ${local.dc1_shutdown_command}; ${local.dc1_exit_code_hack}"
}

# Create the security group to access DC1
resource "azurerm_network_security_group" "dc1-vm-nsg" {
  depends_on=[azurerm_resource_group.network-rg]

  name                = "${var.ad_dc1_name}-nsg"
  location            = azurerm_resource_group.network-rg.location
  resource_group_name = azurerm_resource_group.network-rg.name

  security_rule {
    name                       = "AllowRDP"
    description                = "Allow RDP"
    priority                   = 150
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
  tags = {
    application = var.app_name
    environment = var.environment
  }
}

# Get an External IP for DC1
resource "azurerm_public_ip" "dc1-eip" {
  depends_on=[azurerm_resource_group.network-rg]

  name                = "${var.ad_dc1_name}-eip"
  location            = azurerm_resource_group.network-rg.location
  resource_group_name = azurerm_resource_group.network-rg.name
  allocation_method   = "Static"
  
  tags = { 
    application = var.app_name
    environment = var.environment
  }
}

# Create a NIC for DC1
resource "azurerm_network_interface" "dc1-nic" {
  depends_on=[azurerm_public_ip.dc1-eip]

  name                    = "${var.ad_dc1_name}-nic"
  location                = azurerm_resource_group.network-rg.location
  resource_group_name     = azurerm_resource_group.network-rg.name
  internal_dns_name_label = var.ad_dc1_name
  dns_servers             = local.dns_servers

  ip_configuration {
    name                          = "${var.ad_dc1_name}-ip-config"
    subnet_id                     = azurerm_subnet.network-subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.ad_dc1_ip_address
    public_ip_address_id          = azurerm_public_ip.dc1-eip.id
  }

  tags = { 
    application = var.app_name
    environment = var.environment
  }
}

# DC1 virtual machine
resource "azurerm_windows_virtual_machine" "dc1-vm" {
 
  name                = "${var.ad_dc1_name}-vm"
  computer_name       = "${var.ad_dc1_name}-vm"
  location            = azurerm_resource_group.network-rg.location
  resource_group_name = azurerm_resource_group.network-rg.name
  availability_set_id = azurerm_availability_set.dc-availability-set.id
  
  size           = var.dc1_vm_size
  admin_username = var.ad_admin_username
  admin_password = var.ad_admin_password
  license_type   = var.dc1_license_type

  network_interface_ids = [azurerm_network_interface.dc1-nic.id]

  os_disk {
    name                 = "${var.ad_dc1_name}-vm-os-disk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = var.windows_2022_sku
    version   = "latest"
  }

  enable_automatic_updates = true
  provision_vm_agent       = true

  tags = {
    application = var.app_name
    environment = var.environment 
  }
}

# DC1 virtual machine extension - Install and configure AD
resource "azurerm_virtual_machine_extension" "dc1-vm-extension" {
  depends_on=[azurerm_windows_virtual_machine.dc1-vm]

  name                 = "${var.ad_dc1_name}-vm-active-directory"
  virtual_machine_id   = azurerm_windows_virtual_machine.dc1-vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"  
  settings = <<SETTINGS
  {
    "commandToExecute": "powershell.exe -Command \"${local.dc1_powershell_command}\""
  }
  SETTINGS

  tags = { 
    application = var.app_name
    environment = var.environment
  }
}
