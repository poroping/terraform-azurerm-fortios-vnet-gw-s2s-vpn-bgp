output "fgt_vpn_interface_name" {
  description = "The name of the Fortigate VPN interface"
  value       = fortios_vpnipsec_phase1interface.vpn_p1.name
}

output "fgt_vpn_interface_ip" {
  description = "The IP of the Fortigate VPN interface and BGP peering IP address"
  value       = var.fgt_bgp_peering_ip
}

output "fgt_bgp_asn" {
  description = "The BGP ASN of the Fortigate"
  value       = var.fgt_bgp_asn
}

output "az_bgp_peering_ip" {
  description = "The BGP peering IP address of the Azure VNET gateway"
  value       = data.azurerm_virtual_network_gateway.vnet_gw.bgp_settings[0]["peering_address"]
}

output "az_bgp_asn" {
  description = "The BGP ASN of the Azure VNET gateway"
  value       = data.azurerm_virtual_network_gateway.vnet_gw.bgp_settings[0]["asn"]
}

output "az_vnet_gw_public_ip_address" {
  description = "The public IP address assigned to the VNET gateway"
  value       = data.azurerm_public_ip.az_vpn_gw_ip.ip_address
}

output "vpn_psk" {
  description = "The randomly generated PSK"
  value       = random_password.vpn_psk.result
}
