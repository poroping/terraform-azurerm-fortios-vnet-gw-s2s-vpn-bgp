### Common vars

variable "psk_override" {
  type        = string
  description = "Manually define PSK to use for VPN"
  default     = null
}

### Azure vars

variable "azure_vnet_gw" {
  type        = string
  description = "Name of VNET gateway to create S2S VPN with"
}

variable "azure_rg_name" {
  type        = string
  description = "Name of resource group VNET gateway exists in (additional resources will be created within this group)"
}

variable "azure_local_net_gw_name" {
  type        = string
  description = "Name of local network gateway"
  default     = null
}

variable "azure_vnet_gw_conn_name" {
  type        = string
  description = "Name of VNET gateway connection"
  default     = null
}

variable "azure_ipsec_policy" {
  type = object({
    dh_group         = string
    ike_encryption   = string
    ike_integrity    = string
    ipsec_encryption = string
    ipsec_integrity  = string
    pfs_group        = string
    sa_lifetime      = number
    sa_datasize      = number
    }
  )
  description = "IPSEC policy to apply to Azure tunnel. Ref: https://docs.microsoft.com/en-us/azure/vpn-gateway/ipsec-ike-policy-howto"
  default = {
    dh_group         = "DHGroup14"
    ike_encryption   = "AES256"
    ike_integrity    = "SHA256"
    ipsec_encryption = "AES256"
    ipsec_integrity  = "SHA256"
    pfs_group        = "PFS2048"
    sa_lifetime      = 28800
    sa_datasize      = null
  }
}

### Fortigate vars

variable "fgt_bgp_peering_ip" {
  type        = string
  description = "IP to assign to tunnel interface/BGP source on Fortigate"
  default     = "172.31.255.255"
}

variable "fgt_bgp_asn" {
  type        = number
  description = "BGP ASN to use on Fortigate (Azure only supports EBGP peering)"
  default     = 65501
}

variable "fgt_vdom" {
  type        = string
  description = "VDOM on Fortigate to create VPN in"
  default     = "root"
}

variable "fgt_gateway_ip" {
  type        = string
  description = "External IP on Fortigate used for VPN"
}

variable "fgt_parent_interface" {
  type        = string
  description = "Name of Fortigate interface to bind tunnel to"
}

variable "fgt_vpn_int_name" {
  type        = string
  description = "Name of VPN interface on Fortigate"
  default     = null
}

variable "fgt_ipsec_policy" {
  type = object({
    phase1 = object({
      dhgrp    = number
      proposal = string
    })
    phase2 = object({
      dhgrp          = number
      proposal       = string
      keylife_type   = string
      keylifeseconds = number
      keylifekbs     = number
    })
  })
  description = "IPSEC policy to apply to Fortigate tunnel"
  default = {
    phase1 = {
      dhgrp    = 14
      proposal = "aes256-sha256"
    }
    phase2 = {
      dhgrp          = 14
      proposal       = "aes256-sha256"
      keylife_type   = "seconds"
      keylifeseconds = 27000
      keylifekbs     = null
    }
  }
}