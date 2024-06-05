resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = var.respurce_group_name
}

# Create virtual network
resource "azurerm_virtual_network" "vnet" {
  name                = "my-first-terraform-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}


##################################### jenkins


resource "azurerm_subnet" "web-subnet" {
  name                 = "web-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}


#create public ip(web)
resource "azurerm_public_ip" "web_public_ip" {
  name                = "Public_ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

#open 22/8080 for everybody
resource "azurerm_network_security_group" "web-nsg" {
  name                = "web-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "allow_ssh"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow_jenkins"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

}

# Create network interface(web)
resource "azurerm_network_interface" "web_nic" {
  name                = "web_nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "web_nic_configuration"
    subnet_id                     = azurerm_subnet.web-subnet.id
    private_ip_address            = "10.0.1.10"
    private_ip_address_allocation = "Static"
    public_ip_address_id          = azurerm_public_ip.web_public_ip.id
  }
}


resource "azurerm_network_interface_security_group_association" "example" {
    network_interface_id      = azurerm_network_interface.web_nic.id
    network_security_group_id = azurerm_network_security_group.web-nsg.id
}


#virtual machine(web)
resource "azurerm_virtual_machine" "example" {
  depends_on = [ azurerm_network_interface.web_nic, azurerm_public_ip.web_public_ip, azurerm_virtual_machine.db-example ]
  name                  = "my-vm"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.web_nic.id]
  vm_size              = "Standard_B2s"


  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  storage_os_disk {
    name              = "myosdisk2"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "azureuser"
    admin_username = "azureuser"
    admin_password = var.web_vm_admin_password
    
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

}

resource "null_resource" installJava{
  depends_on = [ azurerm_virtual_machine.example ]
  provisioner "remote-exec" {
    inline = [ 
      "sudo apt-get update",
      "sudo apt install openjdk-17-jre",
      "java -version"
     ]

  connection {
    host     = azurerm_public_ip.web_public_ip.ip_address
    type     = "ssh"
    user     = "azureuser"
    password = var.web_vm_admin_password
    agent    = "false"
    }
 }
}

resource "null_resource" copyfiles {
  depends_on = [ azurerm_virtual_machine.example ]
  provisioner "file" {
    source      = "jenkins.sh"
    destination = "/tmp/jenkins.sh"
  }
  
  connection {
    host     = azurerm_public_ip.web_public_ip.ip_address
    type     = "ssh"
    user     = "azureuser"
    password = var.web_vm_admin_password
    agent    = "false"
  }
}

resource "null_resource" startscript {
  depends_on = [ azurerm_virtual_machine.example, null_resource.copyfiles ]
  provisioner "remote-exec" {
    inline = [ 
      "sudo apt-get update",
      "sudo chmod +x /tmp/jenkins.sh",
      "sudo bash /tmp/jenkins.sh"
     ]

  connection {
    host     = azurerm_public_ip.web_public_ip.ip_address
    type     = "ssh"
    user     = "azureuser"
    password = var.web_vm_admin_password
    agent    = "false"
    }
 }
}





################################## OUTPUTS


output "web_ip" {
  value = azurerm_public_ip.web_public_ip.ip_address
  description = "web public ip"
}