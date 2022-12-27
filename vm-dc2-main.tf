###################################
## AD DC2 Virtual Machine - Main ##
###################################

# Local variables
locals {
  dc2_fqdn = "${var.ad_dc2_name}.${var.ad_domain_name}"

  dc2_prereq_ad_1 = "Import-Module ServerManager"
  dc2_prereq_ad_2 = "Install-WindowsFeature AD-Domain-Services -IncludeAllSubFeature -IncludeManagementTools"
  dc2_prereq_ad_3 = "Install-WindowsFeature DNS -IncludeAllSubFeature -IncludeManagementTools"
  dc2_prereq_ad_4 = "Import-Module ADDSDeployment"
  dc2_prereq_ad_5 = "Import-Module DnsServer"

  dc2_credentials_1 = "$User = '${var.ad_admin_username}@${var.ad_domain_name}'"
  dc2_credentials_2 = "$PWord = ConvertTo-SecureString -String ${var.ad_admin_password} -AsPlainText -Force"
  dc2_credentials_3 = "$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord"

  dc2_install_ad_1 = "Install-ADDSDomainController -DomainName ${var.ad_domain_name} -Credential $Credential -InstallDns:$true -CreateDnsDelegation:$false "
  dc2_install_ad_2 = "-DatabasePath ${var.ad_database_path} -SysvolPath ${var.ad_sysvol_path} -LogPath ${var.ad_log_path} -NoRebootOnCompletion:$false -Force:$true "
  dc2_install_ad_3 = "-SafeModeAdministratorPassword (ConvertTo-SecureString ${var.ad_safe_mode_administrator_password} -AsPlainText -Force) -CriticalReplicationOnly"

  dc2_shutdown_command   = "shutdown -r -t 10"
  dc2_exit_code_hack     = "exit 0"
  dc2_powershell_command = "${local.dc2_prereq_ad_1}; ${local.dc2_prereq_ad_2}; ${local.dc2_prereq_ad_3}; ${local.dc2_prereq_ad_4}; ${local.dc2_prereq_ad_5}; ${local.dc2_credentials_1}; ${local.dc2_credentials_2}; ${local.dc2_credentials_3}; ${local.dc2_install_ad_1}${local.dc2_install_ad_2}${local.dc2_install_ad_3}; ${local.dc2_shutdown_command}; ${local.dc2_exit_code_hack}"
}

# Create the security group to access DC2
resource "azurerm_network_security_group" "dc2-vm-nsg" {
  depends_on=[azurerm_resource_group.network-rg]

  name                = "${var.ad_dc2_name}-nsg"
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

# Get an External IP for DC2
resource "azurerm_public_ip" "dc2-eip" {
  depends_on=[azurerm_resource_group.network-rg]

  name                = "${var.ad_dc2_name}-eip"
  location            = azurerm_resource_group.network-rg.location
  resource_group_name = azurerm_resource_group.network-rg.name
  allocation_method   = "Static"
  
  tags = { 
    application = var.app_name
    environment = var.environment
  }
}

# Create a NIC for DC2
resource "azurerm_network_interface" "dc2-nic" {
  depends_on=[azurerm_public_ip.dc2-eip]

  name                    = "${var.ad_dc2_name}-nic"
  location                = azurerm_resource_group.network-rg.location
  resource_group_name     = azurerm_resource_group.network-rg.name
  internal_dns_name_label = var.ad_dc2_name
  dns_servers             = local.dns_servers

  ip_configuration {
    name                          = "${var.ad_dc2_name}-ip-config"
    subnet_id                     = azurerm_subnet.network-subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.ad_dc2_ip_address
    public_ip_address_id          = azurerm_public_ip.dc2-eip.id
  }

  tags = { 
    application = var.app_name
    environment = var.environment
  }
}

# DC2 virtual machine
resource "azurerm_windows_virtual_machine" "dc2-vm" {
 
  name                = "${var.ad_dc2_name}-vm"
  computer_name       = "${var.ad_dc2_name}-vm"
  location            = azurerm_resource_group.network-rg.location
  resource_group_name = azurerm_resource_group.network-rg.name
  availability_set_id = azurerm_availability_set.dc-availability-set.id
  
  size           = var.dc2_vm_size
  admin_username = var.ad_admin_username
  admin_password = var.ad_admin_password
  license_type   = var.dc2_license_type

  network_interface_ids = [azurerm_network_interface.dc2-nic.id]

  os_disk {
    name                 = "${var.ad_dc2_name}-vm-os-disk"
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

# DC2 virtual machine extension - Install and configure AD
resource "azurerm_virtual_machine_extension" "dc2-vm-extension" {
  depends_on=[azurerm_windows_virtual_machine.dc2-vm]

  name                 = "${var.ad_dc2_name}-vm-active-directory"
  virtual_machine_id   = azurerm_windows_virtual_machine.dc2-vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"  
  settings = <<SETTINGS
  {
    "commandToExecute": "powershell.exe -Command \"${local.dc2_powershell_command}\""
  }
  SETTINGS

  tags = { 
    application = var.app_name
    environment = var.environment
  }
}
