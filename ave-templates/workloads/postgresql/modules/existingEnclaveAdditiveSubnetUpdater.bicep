targetScope = 'resourceGroup'

@description('Name of the existing Microsoft Mission virtual enclave to update through the Mission RP.')
@minLength(1)
param enclaveName string

@description('New dedicated PostgreSQL subnet name to add to the enclave.')
@minLength(1)
param postgreSqlSubnetName string

@description('Prefix size for the new dedicated PostgreSQL subnet.')
@minValue(1)
param postgreSqlSubnetNetworkPrefixSize int

@description('Optional new private endpoint subnet name. Leave empty to keep using an existing private endpoint subnet.')
param privateEndpointSubnetName string = ''

@description('Prefix size for the optional new private endpoint subnet. Ignored when privateEndpointSubnetName is empty.')
@minValue(0)
param privateEndpointSubnetNetworkPrefixSize int = 0

@description('Name of the private endpoint subnet that downstream resources should consume after the update.')
@minLength(1)
param effectivePrivateEndpointSubnetName string

resource additiveDeployment 'Microsoft.Resources/deployments@2022-09-01' = {
  name: 'missionEnclaveAdditiveSubnetUpdate'
  properties: {
    mode: 'Incremental'
    expressionEvaluationOptions: {
      scope: 'inner'
    }
    parameters: {
      effectivePrivateEndpointSubnetName: {
        value: effectivePrivateEndpointSubnetName
      }
      enclaveName: {
        value: enclaveName
      }
      postgreSqlSubnetName: {
        value: postgreSqlSubnetName
      }
      postgreSqlSubnetNetworkPrefixSize: {
        value: postgreSqlSubnetNetworkPrefixSize
      }
      privateEndpointSubnetName: {
        value: privateEndpointSubnetName
      }
      privateEndpointSubnetNetworkPrefixSize: {
        value: privateEndpointSubnetNetworkPrefixSize
      }
    }
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      languageVersion: '2.0'
      contentVersion: '1.0.0.0'
      parameters: {
        effectivePrivateEndpointSubnetName: {
          type: 'string'
        }
        enclaveName: {
          type: 'string'
        }
        postgreSqlSubnetName: {
          type: 'string'
        }
        postgreSqlSubnetNetworkPrefixSize: {
          type: 'int'
        }
        privateEndpointSubnetName: {
          type: 'string'
        }
        privateEndpointSubnetNetworkPrefixSize: {
          type: 'int'
        }
      }
      variables: {
        liveEnclave: '''
[reference(resourceId('Microsoft.Mission/virtualEnclaves', parameters('enclaveName')), '2026-03-01-preview', 'Full')]
'''
        liveSubnetConfigurations: '''
[variables('liveEnclave').properties.enclaveVirtualNetwork.subnetConfigurations]
'''
        existingSubnetConfigurations: '''
[map(variables('liveSubnetConfigurations'), lambda('subnet', if(empty(lambdaVariables('subnet').subnetDelegation), createObject('networkPrefixSize', lambdaVariables('subnet').networkPrefixSize, 'subnetName', lambdaVariables('subnet').subnetName), createObject('networkPrefixSize', lambdaVariables('subnet').networkPrefixSize, 'subnetDelegation', lambdaVariables('subnet').subnetDelegation, 'subnetName', lambdaVariables('subnet').subnetName))))]
'''
        newSubnetConfigurations: '''
[concat(createArray(createObject('networkPrefixSize', parameters('postgreSqlSubnetNetworkPrefixSize'), 'subnetDelegation', 'Microsoft.DBforPostgreSQL/flexibleServers', 'subnetName', parameters('postgreSqlSubnetName'))), if(empty(parameters('privateEndpointSubnetName')), createArray(), createArray(createObject('networkPrefixSize', parameters('privateEndpointSubnetNetworkPrefixSize'), 'subnetName', parameters('privateEndpointSubnetName')))))]
'''
        mergedSubnetConfigurations: '''
[concat(variables('existingSubnetConfigurations'), variables('newSubnetConfigurations'))]
'''
        normalizedApprovalSettings: '''
[union(
  createObject(
    'connectionCreation',
    if(
      equals(coalesce(tryGet(tryGet(tryGet(tryGet(variables('liveEnclave'), 'properties'), 'approvalSettings'), 'connectionCreation'), 'approvalPolicy'), 'NotRequired'), 'Required'),
      createObject(
        'approvalPolicy', 'Required',
        'mandatoryApprovers', coalesce(tryGet(tryGet(tryGet(tryGet(variables('liveEnclave'), 'properties'), 'approvalSettings'), 'connectionCreation'), 'mandatoryApprovers'), createArray()),
        'minimumApproversRequired', coalesce(tryGet(tryGet(tryGet(tryGet(variables('liveEnclave'), 'properties'), 'approvalSettings'), 'connectionCreation'), 'minimumApproversRequired'), 0)
      ),
      createObject(
        'approvalPolicy', 'NotRequired',
        'mandatoryApprovers', createArray(),
        'minimumApproversRequired', 0
      )
    )
  ),
  createObject(
    'connectionUpdate',
    if(
      equals(coalesce(tryGet(tryGet(tryGet(tryGet(variables('liveEnclave'), 'properties'), 'approvalSettings'), 'connectionUpdate'), 'approvalPolicy'), 'NotRequired'), 'Required'),
      createObject(
        'approvalPolicy', 'Required',
        'mandatoryApprovers', coalesce(tryGet(tryGet(tryGet(tryGet(variables('liveEnclave'), 'properties'), 'approvalSettings'), 'connectionUpdate'), 'mandatoryApprovers'), createArray()),
        'minimumApproversRequired', coalesce(tryGet(tryGet(tryGet(tryGet(variables('liveEnclave'), 'properties'), 'approvalSettings'), 'connectionUpdate'), 'minimumApproversRequired'), 0)
      ),
      createObject(
        'approvalPolicy', 'NotRequired',
        'mandatoryApprovers', createArray(),
        'minimumApproversRequired', 0
      )
    )
  ),
  createObject(
    'enclaveEndpointUpdate',
    if(
      equals(coalesce(tryGet(tryGet(tryGet(tryGet(variables('liveEnclave'), 'properties'), 'approvalSettings'), 'enclaveEndpointUpdate'), 'approvalPolicy'), 'NotRequired'), 'Required'),
      createObject(
        'approvalPolicy', 'Required',
        'mandatoryApprovers', coalesce(tryGet(tryGet(tryGet(tryGet(variables('liveEnclave'), 'properties'), 'approvalSettings'), 'enclaveEndpointUpdate'), 'mandatoryApprovers'), createArray()),
        'minimumApproversRequired', coalesce(tryGet(tryGet(tryGet(tryGet(variables('liveEnclave'), 'properties'), 'approvalSettings'), 'enclaveEndpointUpdate'), 'minimumApproversRequired'), 0)
      ),
      createObject(
        'approvalPolicy', 'NotRequired',
        'mandatoryApprovers', createArray(),
        'minimumApproversRequired', 0
      )
    )
  ),
  createObject(
    'enclaveMaintenanceMode',
    if(
      equals(coalesce(tryGet(tryGet(tryGet(tryGet(variables('liveEnclave'), 'properties'), 'approvalSettings'), 'enclaveMaintenanceMode'), 'approvalPolicy'), 'NotRequired'), 'Required'),
      createObject(
        'approvalPolicy', 'Required',
        'mandatoryApprovers', coalesce(tryGet(tryGet(tryGet(tryGet(variables('liveEnclave'), 'properties'), 'approvalSettings'), 'enclaveMaintenanceMode'), 'mandatoryApprovers'), createArray()),
        'minimumApproversRequired', coalesce(tryGet(tryGet(tryGet(tryGet(variables('liveEnclave'), 'properties'), 'approvalSettings'), 'enclaveMaintenanceMode'), 'minimumApproversRequired'), 0)
      ),
      createObject(
        'approvalPolicy', 'NotRequired',
        'mandatoryApprovers', createArray(),
        'minimumApproversRequired', 0
      )
    )
  )
)]
'''
        enclaveVirtualNetwork: '''
[union(createObject('allowSubnetCommunication', bool(tryGet(variables('liveEnclave').properties.enclaveVirtualNetwork, 'allowSubnetCommunication')), 'subnetConfigurations', variables('mergedSubnetConfigurations')), if(empty(variables('liveEnclave').properties.enclaveVirtualNetwork.customCidrRange), createObject('networkSize', variables('liveEnclave').properties.enclaveVirtualNetwork.networkSize), createObject('customCidrRange', variables('liveEnclave').properties.enclaveVirtualNetwork.customCidrRange, 'networkSize', 'custom')), if(empty(variables('liveEnclave').properties.enclaveVirtualNetwork.networkName), createObject(), createObject('networkName', variables('liveEnclave').properties.enclaveVirtualNetwork.networkName)))]
'''
        updatedProperties: '''
[union(createObject('bastionEnabled', bool(tryGet(variables('liveEnclave').properties, 'bastionEnabled')), 'communityResourceId', variables('liveEnclave').properties.communityResourceId, 'enclaveDefaultSettings', createObject('diagnosticDestination', string(tryGet(variables('liveEnclave').properties.enclaveDefaultSettings, 'diagnosticDestination'))), 'enclaveVirtualNetwork', variables('enclaveVirtualNetwork'), 'approvalSettings', variables('normalizedApprovalSettings'), 'rbacInheritance', variables('liveEnclave').properties.rbacInheritance, 'workloadResourceVisibility', variables('liveEnclave').properties.workloadResourceVisibility), if(empty(variables('liveEnclave').properties.dedicatedHubResourceId), createObject(), createObject('dedicatedHubResourceId', variables('liveEnclave').properties.dedicatedHubResourceId)), if(empty(variables('liveEnclave').properties.enclaveRoleAssignments), createObject(), createObject('enclaveRoleAssignments', variables('liveEnclave').properties.enclaveRoleAssignments)), if(empty(variables('liveEnclave').properties.governedServiceList), createObject(), createObject('governedServiceList', variables('liveEnclave').properties.governedServiceList)), if(empty(variables('liveEnclave').properties.maintenanceModeConfiguration), createObject(), createObject('maintenanceModeConfiguration', variables('liveEnclave').properties.maintenanceModeConfiguration)), if(empty(variables('liveEnclave').properties.monitoringSettings), createObject(), createObject('monitoringSettings', variables('liveEnclave').properties.monitoringSettings)), if(empty(variables('liveEnclave').properties.workloadRoleAssignments), createObject(), createObject('workloadRoleAssignments', variables('liveEnclave').properties.workloadRoleAssignments)))]
'''
      }
      resources: [
        {
          type: 'Microsoft.Mission/virtualEnclaves'
          apiVersion: '2026-03-01-preview'
          name: '''
[parameters('enclaveName')]
'''
          location: '''
[variables('liveEnclave').location]
'''
          identity: '''
[variables('liveEnclave').identity]
'''
          tags: '''
[variables('liveEnclave').tags]
'''
          properties: '''
[variables('updatedProperties')]
'''
        }
      ]
      outputs: {
        location: {
          type: 'string'
          value: '''
[reference(resourceId('Microsoft.Mission/virtualEnclaves', parameters('enclaveName')), '2026-03-01-preview', 'Full').location]
'''
        }
        maintenancePrincipals: {
          type: 'array'
          value: '''
[coalesce(tryGet(tryGet(reference(resourceId('Microsoft.Mission/virtualEnclaves', parameters('enclaveName')), '2026-03-01-preview', 'Full').properties, 'maintenanceModeConfiguration'), 'principals'), createArray())]
'''
        }
        managedResourceGroupName: {
          type: 'string'
          value: '''
[reference(resourceId('Microsoft.Mission/virtualEnclaves', parameters('enclaveName')), '2026-03-01-preview', 'Full').properties.managedResourceGroupName]
'''
        }
        postgreSqlSubnet: {
          type: 'object'
          value: '''
[first(filter(reference(resourceId('Microsoft.Mission/virtualEnclaves', parameters('enclaveName')), '2026-03-01-preview', 'Full').properties.enclaveVirtualNetwork.subnetConfigurations, lambda('subnet', equals(toLower(lambdaVariables('subnet').subnetName), toLower(parameters('postgreSqlSubnetName'))))))]
'''
        }
        privateEndpointSubnet: {
          type: 'object'
          value: '''
[first(filter(reference(resourceId('Microsoft.Mission/virtualEnclaves', parameters('enclaveName')), '2026-03-01-preview', 'Full').properties.enclaveVirtualNetwork.subnetConfigurations, lambda('subnet', equals(toLower(lambdaVariables('subnet').subnetName), toLower(parameters('effectivePrivateEndpointSubnetName'))))))]
'''
        }
        resourceId: {
          type: 'string'
          value: '''
[resourceId('Microsoft.Mission/virtualEnclaves', parameters('enclaveName'))]
'''
        }
        subnetConfigurations: {
          type: 'array'
          value: '''
[reference(resourceId('Microsoft.Mission/virtualEnclaves', parameters('enclaveName')), '2026-03-01-preview', 'Full').properties.enclaveVirtualNetwork.subnetConfigurations]
'''
        }
        vnetName: {
          type: 'string'
          value: '''
[reference(resourceId('Microsoft.Mission/virtualEnclaves', parameters('enclaveName')), '2026-03-01-preview', 'Full').properties.enclaveVirtualNetwork.networkName]
'''
        }
      }
    }
  }
}

output resourceId string = additiveDeployment.properties.outputs.resourceId.value
output location string = additiveDeployment.properties.outputs.location.value
output managedResourceGroupName string = additiveDeployment.properties.outputs.managedResourceGroupName.value
output vnetName string = additiveDeployment.properties.outputs.vnetName.value
output vnetResourceId string = resourceId(subscription().subscriptionId, additiveDeployment.properties.outputs.managedResourceGroupName.value, 'Microsoft.Network/virtualNetworks', additiveDeployment.properties.outputs.vnetName.value)
output maintenancePrincipals array = additiveDeployment.properties.outputs.maintenancePrincipals.value
output postgreSqlSubnet object = {
  addressPrefix: string(additiveDeployment.properties.outputs.postgreSqlSubnet.value.addressPrefix)
  name: string(additiveDeployment.properties.outputs.postgreSqlSubnet.value.subnetName)
  networkPrefixSize: int(additiveDeployment.properties.outputs.postgreSqlSubnet.value.networkPrefixSize)
  networkSecurityGroupResourceId: string(additiveDeployment.properties.outputs.postgreSqlSubnet.value.networkSecurityGroupResourceId)
  resourceId: string(additiveDeployment.properties.outputs.postgreSqlSubnet.value.subnetResourceId)
  subnetDelegation: string(additiveDeployment.properties.outputs.postgreSqlSubnet.value.?subnetDelegation ?? '')
}
output privateEndpointSubnet object = {
  addressPrefix: string(additiveDeployment.properties.outputs.privateEndpointSubnet.value.addressPrefix)
  name: string(additiveDeployment.properties.outputs.privateEndpointSubnet.value.subnetName)
  networkPrefixSize: int(additiveDeployment.properties.outputs.privateEndpointSubnet.value.networkPrefixSize)
  networkSecurityGroupResourceId: string(additiveDeployment.properties.outputs.privateEndpointSubnet.value.networkSecurityGroupResourceId)
  resourceId: string(additiveDeployment.properties.outputs.privateEndpointSubnet.value.subnetResourceId)
  subnetDelegation: string(additiveDeployment.properties.outputs.privateEndpointSubnet.value.?subnetDelegation ?? '')
}
output subnetConfigurations array = additiveDeployment.properties.outputs.subnetConfigurations.value
