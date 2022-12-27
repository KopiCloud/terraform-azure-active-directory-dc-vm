# How to Deploy Active Directory (AD) Domain Controller (DC) Virtual Machine (VM) in Azure with Terraform
[![Terraform](https://img.shields.io/badge/terraform-v1.3+-blue.svg)](https://www.terraform.io/downloads.html)

This code:

* Define the Azure Provider
* Create a Resource Group
* Create a VNET
* Create a Subnet
* Create NSG (Network Security Group) for Client Machines to AD Domain Controllers.
* Create NSG (Network Security Group) for Communications between Domain Controllers.
* Create a NIC (Network Card) in this Subnet
* Create the Virtual Machine to Create a New AD Forest and Domain
* Create the Virtual Machine to Join an Existing Domain

## How To deploy the code:

1. Clone the repo
2. Move the files "vm-dc2-main.tf" and "vm-dc2-output.tf" outside the folder
3. Execute "terraform init"
4. Execute "terraform apply"
5. When execution is complete and the DC1 is running, copy the files "vm-dc2-main.tf ", and "vm-dc2-output.tf" back to the folder
6. Execute "terraform apply"
