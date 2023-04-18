targetScope = 'managementGroup'

metadata name = 'ALZ Bicep orchestration - Management Group Diagnostic Settings - ALL'
metadata description = 'Orchestration module that helps enable Diagnostic Settings on the Management Group hierarchy as was defined during the deployment of the Management Group module'

@sys.description('Prefix used for the management group hierarchy in the managementGroups module. Default: alz')
param parTopLevelManagementGroupPrefix string

@sys.description('Log Analytics Workspace Resource ID.')
param parLogAnalyticsWorkspaceResourceId string

@sys.description('Set Parameter to true to Opt-out of deployment telemetry. Default: false')
param parTelemetryOptOut bool = false

var varMgIds = {
  intRoot: parTopLevelManagementGroupPrefix
  platform: 'Platform'
}

// Customer Usage Attribution Id
var varCuaid = 'f49c8dfb-c0ce-4ee0-b316-5e4844474dd0'

module modMgDiagSet '../../modules/mgDiagSettings/mgDiagSettings.bicep' = [for mgId in items(varMgIds): {
  scope: managementGroup(mgId.value)
  name: 'mg-diag-set-${mgId.value}'
  params: {
    parLogAnalyticsWorkspaceResourceId: parLogAnalyticsWorkspaceResourceId
  }
}]

// Optional Deployment for Customer Usage Attribution
module modCustomerUsageAttribution '../../CRML/customerUsageAttribution/cuaIdManagementGroup.bicep' = if (!parTelemetryOptOut) {
  #disable-next-line no-loc-expr-outside-params //Only to ensure telemetry data is stored in same location as deployment. See https://github.com/Azure/ALZ-Bicep/wiki/FAQ#why-are-some-linter-rules-disabled-via-the-disable-next-line-bicep-function for more information //Only to ensure telemetry data is stored in same location as deployment. See https://github.com/Azure/ALZ-Bicep/wiki/FAQ#why-are-some-linter-rules-disabled-via-the-disable-next-line-bicep-function for more information
  name: 'pid-${varCuaid}-${uniqueString(deployment().location)}'
  scope: managementGroup()
  params: {}
}
