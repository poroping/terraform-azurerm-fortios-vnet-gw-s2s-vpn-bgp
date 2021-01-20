terraform {
  required_providers {
    fortios = {
      source  = "fortinetdev/fortios"
      version = ">= 1.7.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.41.0"
    }
  }
}

# Setup & gather info

locals {
  fgt_vpn_int_name        = lower("az-vpn-${random_password.uid_suffix.result}")
  azure_local_net_gw_name = lower("${var.azure_rg_name}-local-net-gw-${random_password.uid_suffix.result}")
  azure_vnet_gw_conn_name = lower("${var.azure_rg_name}-vnet-gw-conn-${random_password.uid_suffix.result}")
}

resource "random_password" "vpn_psk" {
  length  = 16
  special = true
}

resource "random_password" "uid_suffix" {
  length  = 6
  special = false
}

data "azurerm_virtual_network_gateway" "vnet_gw" {
  name                = var.azure_vnet_gw
  resource_group_name = var.azure_rg_name
}

data "azurerm_public_ip" "az_vpn_gw_ip" {
  name                = element(split("/", data.azurerm_virtual_network_gateway.vnet_gw.ip_configuration[0]["public_ip_address_id"]), length(split("/", data.azurerm_virtual_network_gateway.vnet_gw.ip_configuration[0]["public_ip_address_id"])) - 1)
  resource_group_name = data.azurerm_virtual_network_gateway.vnet_gw.resource_group_name
}

# Azure resources

resource "azurerm_local_network_gateway" "local_net_gw" {
  name                = var.azure_local_net_gw_name == null ? local.azure_local_net_gw_name : var.azure_local_net_gw_name
  location            = data.azurerm_virtual_network_gateway.vnet_gw.location
  resource_group_name = data.azurerm_virtual_network_gateway.vnet_gw.resource_group_name
  gateway_address     = var.fgt_gateway_ip
  address_space       = ["${var.fgt_bgp_peering_ip}/32"]
  bgp_settings {
    asn                 = var.fgt_bgp_asn
    bgp_peering_address = var.fgt_bgp_peering_ip
    peer_weight         = 0
  }
}

resource "azurerm_virtual_network_gateway_connection" "vnet_gw_conn" {
  name                = var.azure_vnet_gw_conn_name == null ? local.azure_vnet_gw_conn_name : var.azure_vnet_gw_conn_name
  location            = data.azurerm_virtual_network_gateway.vnet_gw.location
  resource_group_name = data.azurerm_virtual_network_gateway.vnet_gw.resource_group_name

  type                       = "IPsec"
  enable_bgp                 = true
  virtual_network_gateway_id = data.azurerm_virtual_network_gateway.vnet_gw.id
  local_network_gateway_id   = azurerm_local_network_gateway.local_net_gw.id

  shared_key = var.psk_override == null ? random_password.vpn_psk.result : var.psk_override

  dynamic "ipsec_policy" {
    for_each = [var.azure_ipsec_policy]

    content {
      dh_group         = ipsec_policy.value["dh_group"]
      ike_encryption   = ipsec_policy.value["ike_encryption"]
      ike_integrity    = ipsec_policy.value["ike_integrity"]
      ipsec_encryption = ipsec_policy.value["ipsec_encryption"]
      ipsec_integrity  = ipsec_policy.value["ipsec_integrity"]
      pfs_group        = ipsec_policy.value["pfs_group"]
      sa_lifetime      = ipsec_policy.value["sa_lifetime"] == null ? null : ipsec_policy.value["sa_lifetime"]
      sa_datasize      = ipsec_policy.value["sa_datasize"] == null ? null : ipsec_policy.value["sa_datasize"]
    }
  }
}

# Fortigate resources

resource "fortios_vpnipsec_phase1interface" "vpn_p1" {
  authmethod         = "psk"
  dhgrp              = var.fgt_ipsec_policy.phase1.dhgrp
  ike_version        = "2"
  interface          = var.fgt_parent_interface
  ip_version         = "4"
  keylife            = 28800
  mesh_selector_type = "disable"
  name               = var.fgt_vpn_int_name == null ? local.fgt_vpn_int_name : var.fgt_vpn_int_name
  nattraversal       = "disable"
  peertype           = "any"
  proposal           = var.fgt_ipsec_policy.phase1.proposal
  psksecret          = var.psk_override == null ? random_password.vpn_psk.result : var.psk_override
  rekey              = "enable"
  remote_gw          = data.azurerm_public_ip.az_vpn_gw_ip.ip_address
  type               = "static"
  net_device         = "disable"
}

resource "fortios_vpnipsec_phase2interface" "vpn_p2" {
  auto_negotiate = "enable"
  dst_addr_type  = "subnet"
  dst_subnet     = "0.0.0.0 0.0.0.0"
  keylife_type   = var.fgt_ipsec_policy.phase2.keylife_type
  keylifekbs     = var.fgt_ipsec_policy.phase2.keylifekbs
  keylifeseconds = var.fgt_ipsec_policy.phase2.keylifeseconds
  name           = fortios_vpnipsec_phase1interface.vpn_p1.name
  dhgrp          = var.fgt_ipsec_policy.phase2.dhgrp
  pfs            = var.fgt_ipsec_policy.phase2.dhgrp == null ? null : "enable"
  phase1name     = fortios_vpnipsec_phase1interface.vpn_p1.name
  proposal       = var.fgt_ipsec_policy.phase2.proposal
  replay         = "enable"
  src_addr_type  = "subnet"
  src_subnet     = "0.0.0.0 0.0.0.0"

  depends_on = [fortios_vpnipsec_phase1interface.vpn_p1]
}

resource "fortios_system_interface" "vpn_interface" {
  vdom          = var.fgt_vdom
  name          = fortios_vpnipsec_phase1interface.vpn_p1.name
  ip            = "${var.fgt_bgp_peering_ip} 255.255.255.255"
  remote_ip     = "${data.azurerm_virtual_network_gateway.vnet_gw.bgp_settings[0]["peering_address"]} 255.255.255.255"
  tcp_mss       = 1350
  autogenerated = "auto"

  depends_on = [fortios_vpnipsec_phase1interface.vpn_p1, fortios_vpnipsec_phase2interface.vpn_p2]
}

resource "fortios_routerbgp_neighbor" "az_neighbor" {
  ip                   = data.azurerm_virtual_network_gateway.vnet_gw.bgp_settings[0]["peering_address"]
  remote_as            = data.azurerm_virtual_network_gateway.vnet_gw.bgp_settings[0]["asn"]
  soft_reconfiguration = "enable"
  update_source        = fortios_vpnipsec_phase1interface.vpn_p1.name

  depends_on = [fortios_system_interface.vpn_interface]
}