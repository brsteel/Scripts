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

#disable-next-line no-deployments-resources
resource inventoryDeployment 'Microsoft.Resources/deployments@2022-09-01' = {
  name: 'missionEnclaveAdditiveSubnetInventory'
  properties: {
    mode: 'Incremental'
    expressionEvaluationOptions: {
      scope: 'inner'
    }
    parameters: {
      enclaveName: {
        value: enclaveName
      }
    }
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      languageVersion: '2.0'
      contentVersion: '1.0.0.0'
      parameters: {
        enclaveName: {
          type: 'string'
        }
      }
      variables: {
        liveEnclave: '''
[reference(resourceId('Microsoft.Mission/virtualEnclaves', parameters('enclaveName')), '2026-03-01-preview', 'Full')]
'''
        liveProperties: '''
[coalesce(tryGet(variables('liveEnclave'), 'properties'), createObject())]
'''
        liveIdentity: '''
[coalesce(tryGet(variables('liveEnclave'), 'identity'), createObject())]
'''
        liveIdentityType: '''
[coalesce(tryGet(variables('liveIdentity'), 'type'), 'None')]
'''
        liveUserAssignedIdentities: '''
[coalesce(tryGet(variables('liveIdentity'), 'userAssignedIdentities'), createObject())]
'''
        liveTags: '''
[coalesce(tryGet(variables('liveEnclave'), 'tags'), createObject())]
'''
        identityRequest: '''
[union(
  createObject('type', variables('liveIdentityType')),
  if(
    or(
      equals(variables('liveIdentityType'), 'UserAssigned'),
      equals(variables('liveIdentityType'), 'SystemAssigned,UserAssigned')
    ),
    createObject(
      'userAssignedIdentities',
      toObject(
        items(variables('liveUserAssignedIdentities')),
        lambda('identity', lambdaVariables('identity').key),
        lambda('identity', createObject())
      )
    ),
    createObject()
  )
)]
'''
        liveEnclaveVirtualNetwork: '''
[coalesce(tryGet(variables('liveProperties'), 'enclaveVirtualNetwork'), createObject())]
'''
        liveSubnetConfigurations: '''
[coalesce(tryGet(variables('liveEnclaveVirtualNetwork'), 'subnetConfigurations'), createArray())]
'''
        normalizedExistingSubnetConfigurations: '''
[map(
  variables('liveSubnetConfigurations'),
  lambda(
    'subnet',
    union(
      createObject(
        'networkPrefixSize', lambdaVariables('subnet').networkPrefixSize,
        'subnetName', lambdaVariables('subnet').subnetName
      ),
      if(
        empty(coalesce(tryGet(lambdaVariables('subnet'), 'subnetDelegation'), '')),
        createObject(),
        createObject('subnetDelegation', lambdaVariables('subnet').subnetDelegation)
      )
    )
  )
)]
'''
        liveApprovalSettings: '''
[coalesce(tryGet(variables('liveProperties'), 'approvalSettings'), createObject())]
'''
        normalizedApprovalSettings: '''
[union(
  createObject(
    'connectionCreation',
    if(
      equals(coalesce(tryGet(tryGet(variables('liveApprovalSettings'), 'connectionCreation'), 'approvalPolicy'), 'NotRequired'), 'Required'),
      createObject(
        'approvalPolicy', 'Required',
        'mandatoryApprovers', coalesce(tryGet(tryGet(variables('liveApprovalSettings'), 'connectionCreation'), 'mandatoryApprovers'), createArray()),
        'minimumApproversRequired', coalesce(tryGet(tryGet(variables('liveApprovalSettings'), 'connectionCreation'), 'minimumApproversRequired'), 0)
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
      equals(coalesce(tryGet(tryGet(variables('liveApprovalSettings'), 'connectionUpdate'), 'approvalPolicy'), 'NotRequired'), 'Required'),
      createObject(
        'approvalPolicy', 'Required',
        'mandatoryApprovers', coalesce(tryGet(tryGet(variables('liveApprovalSettings'), 'connectionUpdate'), 'mandatoryApprovers'), createArray()),
        'minimumApproversRequired', coalesce(tryGet(tryGet(variables('liveApprovalSettings'), 'connectionUpdate'), 'minimumApproversRequired'), 0)
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
      equals(coalesce(tryGet(tryGet(variables('liveApprovalSettings'), 'enclaveEndpointUpdate'), 'approvalPolicy'), 'NotRequired'), 'Required'),
      createObject(
        'approvalPolicy', 'Required',
        'mandatoryApprovers', coalesce(tryGet(tryGet(variables('liveApprovalSettings'), 'enclaveEndpointUpdate'), 'mandatoryApprovers'), createArray()),
        'minimumApproversRequired', coalesce(tryGet(tryGet(variables('liveApprovalSettings'), 'enclaveEndpointUpdate'), 'minimumApproversRequired'), 0)
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
      equals(coalesce(tryGet(tryGet(variables('liveApprovalSettings'), 'enclaveMaintenanceMode'), 'approvalPolicy'), 'NotRequired'), 'Required'),
      createObject(
        'approvalPolicy', 'Required',
        'mandatoryApprovers', coalesce(tryGet(tryGet(variables('liveApprovalSettings'), 'enclaveMaintenanceMode'), 'mandatoryApprovers'), createArray()),
        'minimumApproversRequired', coalesce(tryGet(tryGet(variables('liveApprovalSettings'), 'enclaveMaintenanceMode'), 'minimumApproversRequired'), 0)
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
        liveEnclaveDefaultSettings: '''
[coalesce(tryGet(variables('liveProperties'), 'enclaveDefaultSettings'), createObject())]
'''
        liveDedicatedHubResourceId: '''
[coalesce(tryGet(variables('liveProperties'), 'dedicatedHubResourceId'), '')]
'''
        liveEnclaveRoleAssignments: '''
[coalesce(tryGet(variables('liveProperties'), 'enclaveRoleAssignments'), createArray())]
'''
        liveGovernedServiceList: '''
[coalesce(tryGet(variables('liveProperties'), 'governedServiceList'), createArray())]
'''
        liveMaintenanceModeConfiguration: '''
[coalesce(tryGet(variables('liveProperties'), 'maintenanceModeConfiguration'), createObject())]
'''
        liveMonitoringSettings: '''
[coalesce(tryGet(variables('liveProperties'), 'monitoringSettings'), createObject())]
'''
        liveWorkloadRoleAssignments: '''
[coalesce(tryGet(variables('liveProperties'), 'workloadRoleAssignments'), createArray())]
'''
        liveRbacInheritance: '''
[coalesce(tryGet(variables('liveProperties'), 'rbacInheritance'), '')]
'''
        liveWorkloadResourceVisibility: '''
[coalesce(tryGet(variables('liveProperties'), 'workloadResourceVisibility'), '')]
'''
        liveCustomCidrRange: '''
[coalesce(tryGet(variables('liveEnclaveVirtualNetwork'), 'customCidrRange'), '')]
'''
        liveNetworkSize: '''
[coalesce(tryGet(variables('liveEnclaveVirtualNetwork'), 'networkSize'), '')]
'''
        liveNetworkName: '''
[coalesce(tryGet(variables('liveEnclaveVirtualNetwork'), 'networkName'), '')]
'''
        writableEnclaveVirtualNetwork: '''
[union(
  createObject(
    'subnetConfigurations', variables('normalizedExistingSubnetConfigurations')
  ),
  if(
    contains(variables('liveEnclaveVirtualNetwork'), 'allowSubnetCommunication'),
    createObject('allowSubnetCommunication', bool(tryGet(variables('liveEnclaveVirtualNetwork'), 'allowSubnetCommunication'))),
    createObject()
  ),
  if(
    empty(variables('liveCustomCidrRange')),
    if(
      empty(variables('liveNetworkSize')),
      createObject(),
      createObject('networkSize', variables('liveNetworkSize'))
    ),
    createObject(
      'customCidrRange', variables('liveCustomCidrRange'),
      'networkSize', 'custom'
    )
  ),
  if(
    empty(variables('liveNetworkName')),
    createObject(),
    createObject('networkName', variables('liveNetworkName'))
  )
)]
'''
        writableProperties: '''
[union(
  createObject(
    'communityResourceId', variables('liveProperties').communityResourceId,
    'enclaveVirtualNetwork', variables('writableEnclaveVirtualNetwork'),
    'approvalSettings', variables('normalizedApprovalSettings')
  ),
  if(
    contains(variables('liveProperties'), 'bastionEnabled'),
    createObject('bastionEnabled', bool(tryGet(variables('liveProperties'), 'bastionEnabled'))),
    createObject()
  ),
  if(
    contains(variables('liveEnclaveDefaultSettings'), 'diagnosticDestination'),
    createObject(
      'enclaveDefaultSettings',
      createObject('diagnosticDestination', string(tryGet(variables('liveEnclaveDefaultSettings'), 'diagnosticDestination')))
    ),
    createObject()
  ),
  if(
    empty(variables('liveRbacInheritance')),
    createObject(),
    createObject('rbacInheritance', variables('liveRbacInheritance'))
  ),
  if(
    empty(variables('liveWorkloadResourceVisibility')),
    createObject(),
    createObject('workloadResourceVisibility', variables('liveWorkloadResourceVisibility'))
  ),
  if(
    empty(variables('liveDedicatedHubResourceId')),
    createObject(),
    createObject('dedicatedHubResourceId', variables('liveDedicatedHubResourceId'))
  ),
  if(
    empty(variables('liveEnclaveRoleAssignments')),
    createObject(),
    createObject('enclaveRoleAssignments', variables('liveEnclaveRoleAssignments'))
  ),
  if(
    empty(variables('liveGovernedServiceList')),
    createObject(),
    createObject('governedServiceList', variables('liveGovernedServiceList'))
  ),
  if(
    empty(variables('liveMaintenanceModeConfiguration')),
    createObject(),
    createObject('maintenanceModeConfiguration', variables('liveMaintenanceModeConfiguration'))
  ),
  if(
    empty(variables('liveMonitoringSettings')),
    createObject(),
    createObject('monitoringSettings', variables('liveMonitoringSettings'))
  ),
  if(
    empty(variables('liveWorkloadRoleAssignments')),
    createObject(),
    createObject('workloadRoleAssignments', variables('liveWorkloadRoleAssignments'))
  )
)]
'''
      }
      resources: {}
      outputs: {
        identityRequest: {
          type: 'object'
          value: '''
[variables('identityRequest')]
'''
        }
        location: {
          type: 'string'
          value: '''
[variables('liveEnclave').location]
'''
        }
        normalizedExistingSubnetConfigurations: {
          type: 'array'
          value: '''
[variables('normalizedExistingSubnetConfigurations')]
'''
        }
        tags: {
          type: 'object'
          value: '''
[variables('liveTags')]
'''
        }
        writableProperties: {
          type: 'object'
          value: '''
[variables('writableProperties')]
'''
        }
      }
    }
  }
}

#disable-next-line no-deployments-resources
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
      existingSubnetConfigurations: {
        value: inventoryDeployment.properties.outputs.normalizedExistingSubnetConfigurations.value
      }
      identityRequest: {
        value: inventoryDeployment.properties.outputs.identityRequest.value
      }
      location: {
        value: inventoryDeployment.properties.outputs.location.value
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
      tags: {
        value: inventoryDeployment.properties.outputs.tags.value
      }
      writableProperties: {
        value: inventoryDeployment.properties.outputs.writableProperties.value
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
        existingSubnetConfigurations: {
          type: 'array'
        }
        identityRequest: {
          type: 'object'
        }
        location: {
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
        tags: {
          type: 'object'
        }
        writableProperties: {
          type: 'object'
        }
      }
      variables: {
        newSubnetConfigurations: '''
[concat(
  createArray(
    createObject(
      'networkPrefixSize', parameters('postgreSqlSubnetNetworkPrefixSize'),
      'subnetDelegation', 'Microsoft.DBforPostgreSQL/flexibleServers',
      'subnetName', parameters('postgreSqlSubnetName')
    )
  ),
  if(
    empty(parameters('privateEndpointSubnetName')),
    createArray(),
    createArray(
      createObject(
        'networkPrefixSize', parameters('privateEndpointSubnetNetworkPrefixSize'),
        'subnetName', parameters('privateEndpointSubnetName')
      )
    )
  )
)]
'''
        mergedSubnetConfigurations: '''
[concat(parameters('existingSubnetConfigurations'), variables('newSubnetConfigurations'))]
'''
        updatedEnclaveVirtualNetwork: '''
[union(
  coalesce(tryGet(parameters('writableProperties'), 'enclaveVirtualNetwork'), createObject()),
  createObject('subnetConfigurations', variables('mergedSubnetConfigurations'))
)]
'''
        updatedProperties: '''
[union(
  parameters('writableProperties'),
  createObject('enclaveVirtualNetwork', variables('updatedEnclaveVirtualNetwork'))
)]
'''
      }
      resources: {
        missionVirtualEnclave: {
          type: 'Microsoft.Mission/virtualEnclaves'
          apiVersion: '2026-03-01-preview'
          name: '''
[parameters('enclaveName')]
'''
          location: '''
[parameters('location')]
'''
          identity: '''
[parameters('identityRequest')]
'''
          tags: '''
[parameters('tags')]
'''
          properties: '''
[variables('updatedProperties')]
'''
        }
      }
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
