# terraform-azurerm-fortios-vnet-gw-s2s-vpn-bgp

## Warning

This module uses resource ```fortios_routerbgp_neighbor``` this resource will cause inconsistency issues if the resource ```fortios_router_bgp``` with neighbor blocks is defined elsewhere.

Move all neighbor blocks to the ```fortios_routerbgp_neighbor``` resource to resolve this.

## Requirements

| Name | Version |
|------|---------|
| azurerm | >= 2.41.0 |
| fortios | >= 1.7.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | >= 2.41.0 |
| fortios | >= 1.7.0 |
| random | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| azure\_rg\_name | Name of resource group VNET gateway exists in (additional resources will be created within this group) | `string` | n/a | yes |
| azure\_vnet\_gw | Name of VNET gateway to create S2S VPN with | `string` | n/a | yes |
| fgt\_gateway\_ip | External IP on Fortigate used for VPN | `string` | n/a | yes |
| fgt\_parent\_interface | Name of Fortigate interface to bind tunnel to | `string` | n/a | yes |
| azure\_ipsec\_policy | IPSEC policy to apply to Azure tunnel. Ref: https://docs.microsoft.com/en-us/azure/vpn-gateway/ipsec-ike-policy-howto | <pre>object({<br>    dh_group         = string<br>    ike_encryption   = string<br>    ike_integrity    = string<br>    ipsec_encryption = string<br>    ipsec_integrity  = string<br>    pfs_group        = string<br>    sa_lifetime      = number<br>    sa_datasize      = number<br>    }<br>  )</pre> | <pre>{<br>  "dh_group": "DHGroup14",<br>  "ike_encryption": "AES256",<br>  "ike_integrity": "SHA256",<br>  "ipsec_encryption": "AES256",<br>  "ipsec_integrity": "SHA256",<br>  "pfs_group": "PFS2048",<br>  "sa_datasize": null,<br>  "sa_lifetime": 28800<br>}</pre> | no |
| azure\_local\_net\_gw\_name | Name of local network gateway | `string` | `null` | no |
| azure\_vnet\_gw\_conn\_name | Name of VNET gateway connection | `string` | `null` | no |
| fgt\_bgp\_asn | BGP ASN to use on Fortigate (Azure only supports EBGP peering) | `number` | `65501` | no |
| fgt\_bgp\_peering\_ip | IP to assign to tunnel interface/BGP source on Fortigate | `string` | `"172.31.255.255"` | no |
| fgt\_ipsec\_policy | IPSEC policy to apply to Fortigate tunnel | <pre>object({<br>    phase1 = object({<br>      dhgrp    = number<br>      proposal = string<br>    })<br>    phase2 = object({<br>      dhgrp          = number<br>      proposal       = string<br>      keylife_type   = string<br>      keylifeseconds = number<br>      keylifekbs     = number<br>    })<br>  })</pre> | <pre>{<br>  "phase1": {<br>    "dhgrp": 14,<br>    "proposal": "aes256-sha256"<br>  },<br>  "phase2": {<br>    "dhgrp": 14,<br>    "keylife_type": "seconds",<br>    "keylifekbs": null,<br>    "keylifeseconds": 27000,<br>    "proposal": "aes256-sha256"<br>  }<br>}</pre> | no |
| fgt\_vdom | VDOM on Fortigate to create VPN in | `string` | `"root"` | no |
| fgt\_vpn\_int\_name | Name of VPN interface on Fortigate | `string` | `null` | no |
| psk\_override | Manually define PSK to use for VPN | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| az\_bgp\_asn | The BGP ASN of the Azure VNET gateway |
| az\_bgp\_peering\_ip | The BGP peering IP address of the Azure VNET gateway |
| az\_vnet\_gw\_public\_ip\_address | The public IP address assigned to the VNET gateway |
| fgt\_bgp\_asn | The BGP ASN of the Fortigate |
| fgt\_vpn\_interface\_ip | The IP of the Fortigate VPN interface and BGP peering IP address |
| fgt\_vpn\_interface\_name | The name of the Fortigate VPN interface |
| vpn\_psk | The randomly generated PSK |