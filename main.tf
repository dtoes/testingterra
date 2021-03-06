resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-resources"
  location = var.location
      tags = {
        environment = "${var.omgeving}"
    }
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
        tags = {
        environment = "${var.omgeving}"
    }
}

resource "azurerm_subnet" "intern" {
  name                 = "intern"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefix       = "10.0.1.0/24"
}

resource "azurerm_public_ip" "mypubliclinuxip" {
    name                         = "${var.prefix}-lxpip"
    location                     = azurerm_resource_group.main.location
    resource_group_name          = azurerm_resource_group.main.name
    allocation_method            = "Static"

    tags = {
        environment = "${var.omgeving}"
    }
}

resource "azurerm_network_interface" "linux" {
  name                = "${var.prefix}-lxnic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.intern.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.mypubliclinuxip.id
  }
            tags = {
        environment = "${var.omgeving}"
    }
}

resource "azurerm_network_security_group" "webserver" {
  name                = "http_webserver"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  security_rule {
    access                     = "Allow"
    direction                  = "Inbound"
    name                       = "http"
    priority                   = 100
    protocol                   = "Tcp"
    source_port_range          = "*"
    source_address_prefix      = "*"
    destination_port_range     = "443"
    destination_address_prefix = azurerm_subnet.intern.address_prefix
  }
    security_rule {
    access                     = "Allow"
    direction                  = "Inbound"
    name                       = "ssh"
    priority                   = 110
    protocol                   = "Tcp"
    source_port_range          = "*"
    source_address_prefix      = "*"
    destination_port_range     = "22"
    destination_address_prefix = azurerm_subnet.intern.address_prefix
  }
        tags = {
        environment = "${var.omgeving}"
    }
}

resource "azurerm_virtual_machine" "example" {
  name                  = "${var.prefix}-lx"
  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  network_interface_ids = [azurerm_network_interface.linux.id]
  vm_size               = "Standard_F2"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.prefix}-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "Linux machine"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  

  os_profile_linux_config {
    disable_password_authentication = false
  }


  tags = {
    environment = "${var.omgeving}"
    }
}