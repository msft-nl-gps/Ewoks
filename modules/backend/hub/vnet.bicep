metadata name = 'ALZ Bicep - Spoke Networking module'
metadata description = 'This module creates spoke networking resources'

@sys.description('The Azure Region to deploy the resources into.')
param parLocation string = resourceGroup().location

@sys.description('Switch to enable/disable BGP Propagation on route table.')
param parDisableBgpRoutePropagation bool = false

@sys.description('Id of the DdosProtectionPlan which will be applied to the Virtual Network.')
param parDdosProtectionPlanId string = ''

@sys.description('The IP address range for all virtual networks to use.')
param parSpokeNetworkAddressPrefix string

@sys.description('A list of subnets in a Virtual Network')
param vnetSubnets array

@sys.description('The Name of the Spoke Virtual Network.')
param parSpokeNetworkName string = 'vnet-spoke'

@sys.description('Array of DNS Server IP addresses for VNet.')
param parDnsServerIps array = []

@sys.description('IP Address where network traffic should route to leveraged with DNS Proxy.')
param parNextHopIpAddress string = ''

@sys.description('Name of Route table to create for the default route of Hub.')
param parSpokeToHubRouteTableName string = 'rtb-spoke-to-hub'

@sys.description('Tags you would like to be applied to all resources in this module.')
param parTags object = {}

//If Ddos parameter is true Ddos will be Enabled on the Virtual Network
//If Azure Firewall is enabled and Network DNS Proxy is enabled DNS will be configured to point to AzureFirewall
resource resSpokeVirtualNetwork 'Microsoft.Network/virtualNetworks@2021-08-01' = {
  name: parSpokeNetworkName
  location: parLocation
  tags: parTags
  properties: {
    addressSpace: {
      addressPrefixes: [
        parSpokeNetworkAddressPrefix
      ]
    }
    subnets: vnetSubnets
    enableDdosProtection: (!empty(parDdosProtectionPlanId) ? true : false)
    ddosProtectionPlan: (!empty(parDdosProtectionPlanId) ? true : false) ? {
      id: parDdosProtectionPlanId
    } : null
    dhcpOptions: (!empty(parDnsServerIps) ? true : false) ? {
      dnsServers: parDnsServerIps
    } : null
  }
}

resource resSpokeToHubRouteTable 'Microsoft.Network/routeTables@2021-08-01' = if (!empty(parNextHopIpAddress)) {
  name: parSpokeToHubRouteTableName
  location: parLocation
  tags: parTags
  properties: {
    routes: [
      {
        name: 'udr-default-to-hub-nva'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: parNextHopIpAddress
        }
      }
    ]
    disableBgpRoutePropagation: parDisableBgpRoutePropagation
  }
}

output outSpokeVirtualNetworkName string = resSpokeVirtualNetwork.name
output outSpokeVirtualNetworkId string = resSpokeVirtualNetwork.id
