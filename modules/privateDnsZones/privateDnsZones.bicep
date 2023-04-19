metadata name = 'ALZ Bicep - Private DNS Zones'
metadata description = 'Module used to set up Private DNS Zones in accordance to Azure Landing Zones'

@sys.description('The Azure Region to deploy the resources into.')
param parLocation string = resourceGroup().location

@sys.description('Array of custom DNS Zones to provision in Hub Virtual Network.')
param parPrivateDnsZones array = [
]

@sys.description('Tags you would like to be applied to all resources in this module.')
param parTags object = {}

@sys.description('Resource ID of VNet for Private DNS Zone VNet Links.')
param parVirtualNetworkIdToLink string = ''

@sys.description('Set Parameter to true to Opt-out of deployment telemetry.')
param parTelemetryOptOut bool = false

var varAzBackupGeoCodes = {
  australiacentral: 'acl'
  australiacentral2: 'acl2'
  australiaeast: 'ae'
  australiasoutheast: 'ase'
  brazilsouth: 'brs'
  brazilsoutheast: 'bse'
  centraluseuap: 'ccy'
  canadacentral: 'cnc'
  canadaeast: 'cne'
  centralus: 'cus'
  eastasia: 'ea'
  eastus2euap: 'ecy'
  eastus: 'eus'
  eastus2: 'eus2'
  francecentral: 'frc'
  francesouth: 'frs'
  germanynorth: 'gn'
  germanywestcentral: 'gwc'
  centralindia: 'inc'
  southindia: 'ins'
  westindia: 'inw'
  japaneast: 'jpe'
  japanwest: 'jpw'
  jioindiacentral: 'jic'
  jioindiawest: 'jiw'
  koreacentral: 'krc'
  koreasouth: 'krs'
  northcentralus: 'ncus'
  northeurope: 'ne'
  norwayeast: 'nwe'
  norwaywest: 'nww'
  qatarcentral: 'qac'
  southafricanorth: 'san'
  southafricawest: 'saw'
  southcentralus: 'scus'
  swedencentral: 'sdc'
  swedensouth: 'sds'
  southeastasia: 'sea'
  switzerlandnorth: 'szn'
  switzerlandwest: 'szw'
  uaecentral: 'uac'
  uaenorth: 'uan'
  uksouth: 'uks'
  ukwest: 'ukw'
  westcentralus: 'wcus'
  westeurope: 'we'
  westus: 'wus'
  westus2: 'wus2'
  westus3: 'wus3'
  usdodcentral: 'udc'
  usdodeast: 'ude'
  usgovarizona: 'uga'
  usgoviowa: 'ugi'
  usgovtexas: 'ugt'
  usgovvirginia: 'ugv'
  usnateast: 'exe'
  usnatwest: 'exw'
  usseceast: 'rxe'
  ussecwest: 'rxw'
  chinanorth: 'bjb'
  chinanorth2: 'bjb2'
  chinanorth3: 'bjb3'
  chinaeast: 'sha'
  chinaeast2: 'sha2'
  chinaeast3: 'sha3'
  germanycentral: 'gec'
  germanynortheast: 'gne'
}

// If region entered in parLocation and matches a lookup to varAzBackupGeoCodes then insert Azure Backup Private DNS Zone with appropriate geo code inserted alongside zones in parPrivateDnsZones. If not just return parPrivateDnsZones
var varPrivateDnsZonesMerge = contains(varAzBackupGeoCodes, parLocation) ? union(parPrivateDnsZones, [ 'privatelink.${varAzBackupGeoCodes[toLower(parLocation)]}.backup.windowsazure.com' ]) : parPrivateDnsZones

// Customer Usage Attribution Id
var varCuaid = '981733dd-3195-4fda-a4ee-605ab959edb6'

resource resPrivateDnsZones 'Microsoft.Network/privateDnsZones@2020-06-01' = [for privateDnsZone in varPrivateDnsZonesMerge: {
  name: privateDnsZone
  location: 'global'
  tags: parTags
}]

resource resVirtualNetworkLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = [for privateDnsZoneName in varPrivateDnsZonesMerge: if (!empty(parVirtualNetworkIdToLink)) {
  name: '${privateDnsZoneName}/${take('link-${uniqueString(parVirtualNetworkIdToLink)}', 80)}'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: parVirtualNetworkIdToLink
    }
  }
  dependsOn: resPrivateDnsZones
}]

module modCustomerUsageAttribution '../../CRML/customerUsageAttribution/cuaIdResourceGroup.bicep' = if (!parTelemetryOptOut) {
  #disable-next-line no-loc-expr-outside-params
  name: 'pid-${varCuaid}-${uniqueString(resourceGroup().location)}'
  params: {}
}

output outPrivateDnsZones array = [for i in range(0, length(varPrivateDnsZonesMerge)): {
  name: resPrivateDnsZones[i].name
  id: resPrivateDnsZones[i].id
}]
