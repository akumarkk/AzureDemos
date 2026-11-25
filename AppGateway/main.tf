locals {
  empty = var.explicit_empty ? "" : null
}

resource "azurerm_resource_group" "demo" {
  name     = var.resource_group_name
  location = var.location
  tags     = { purpose = "appgw-plan-demo", temporary = "true" }
}

resource "azurerm_virtual_network" "demo" {
  name                = "azedemo-vnet"
  resource_group_name = azurerm_resource_group.demo.name
  location            = azurerm_resource_group.demo.location
  address_space       = ["10.250.0.0/24"]
}

resource "azurerm_subnet" "demo" {
  name                 = "appgw"
  resource_group_name  = azurerm_resource_group.demo.name
  virtual_network_name = azurerm_virtual_network.demo.name
  address_prefixes     = ["10.250.0.0/26"]
}

resource "azurerm_public_ip" "demo" {
  name                = "azedemo-pip"
  resource_group_name = azurerm_resource_group.demo.name
  location            = azurerm_resource_group.demo.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_application_gateway" "demo" {
  name                = "azedemo-appgw"
  resource_group_name = azurerm_resource_group.demo.name
  location            = azurerm_resource_group.demo.location

  sku {
    name = "Standard_v2"
    tier = "Standard_v2"
  }

  autoscale_configuration {
    min_capacity = 0
    max_capacity = 2
  }

  gateway_ip_configuration {
    name      = "gwip"
    subnet_id = azurerm_subnet.demo.id
  }

  frontend_port {
    name = "port_80"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "public"
    public_ip_address_id = azurerm_public_ip.demo.id
  }

  dynamic "backend_address_pool" {
    for_each = var.apps
    content {
      name         = "${backend_address_pool.value}-backend"
      fqdns        = ["www.example.com"]
      ip_addresses = []
    }
  }

  dynamic "probe" {
    for_each = var.apps
    content {
      name                                      = "${probe.value}-probe"
      protocol                                  = "Http"
      path                                      = "/health"
      interval                                  = 30
      timeout                                   = 30
      unhealthy_threshold                       = 3
      minimum_servers                           = 0
      pick_host_name_from_backend_http_settings = true
      host                                      = local.empty
      match {
        body        = local.empty
        status_code = ["200-399"]
      }
    }
  }

  dynamic "backend_http_settings" {
    for_each = var.apps
    content {
      name                                = "${backend_http_settings.value}-setting"
      cookie_based_affinity               = "Disabled"
      path                                = "/${backend_http_settings.value}/"
      port                                = 80
      protocol                            = "Http"
      request_timeout                     = 20
      pick_host_name_from_backend_address = true
      host_name                           = local.empty
      probe_name                          = "${backend_http_settings.value}-probe"
    }
  }

  dynamic "http_listener" {
    for_each = var.apps
    content {
      name                           = "${http_listener.value}-listener"
      frontend_ip_configuration_name = "public"
      frontend_port_name             = "port_80"
      protocol                       = "Http"
      host_name                      = "${http_listener.value}.example.com"
      host_names                     = []
      require_sni                    = false
      ssl_profile_name               = local.empty
    }
  }

  dynamic "request_routing_rule" {
    for_each = var.apps
    content {
      name                       = "${request_routing_rule.value}-rule"
      priority                   = (request_routing_rule.key + 1) * 100
      rule_type                  = "Basic"
      http_listener_name         = "${request_routing_rule.value}-listener"
      backend_address_pool_name  = "${request_routing_rule.value}-backend"
      backend_http_settings_name = "${request_routing_rule.value}-setting"
    }
  }
}
