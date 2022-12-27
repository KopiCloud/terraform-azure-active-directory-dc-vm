####################
# Common Variables #
####################
company     = "kopicloud"
app_name    = "active directory"
environment = "development"
location    = "northeurope"

##################
# Authentication #
##################
azure-tenant-id       = "complete-this"
azure-subscription-id = "complete-this"
azure-client-id       = "complete-this"
azure-client-secret   = "complete-this"

###########
# Network #
###########
network-vnet-cidr   = "10.127.0.0/16"
network-subnet-cidr = "10.127.1.0/24"

####################
# Active Directory #
####################
ad_domain_name                      = "kopicloud.local"
ad_domain_netbios_name              = "kopicloud"
ad_admin_username                   = "kopiadmin"
ad_admin_password                   = "L30M3ss110"
ad_safe_mode_administrator_password = "R3c0v3ryAcc3ssM0d3"

#####################
# Domain Controller #
#####################
ad_dc1_name       = "kopi-dev-dc1"
ad_dc1_ip_address = "10.127.1.11"
dc1_vm_size       = "Standard_B2s"

ad_dc2_name       = "kopi-dev-dc2"
ad_dc2_ip_address = "10.127.1.12"
dc2_vm_size       = "Standard_B2s"
