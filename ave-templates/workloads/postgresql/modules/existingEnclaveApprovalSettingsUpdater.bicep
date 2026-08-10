targetScope = 'resourceGroup'

type requiredApprovalSettingType = {
  approvalPolicy: 'Required'
  @minLength(1)
  mandatoryApprovers: {
    approverEntraId: string
  }[]
  @minValue(1)
  minimumApproversRequired: int
}

type notRequiredApprovalSettingType = {
  approvalPolicy: 'NotRequired'
}

@discriminator('approvalPolicy')
type approvalSettingType = requiredApprovalSettingType | notRequiredApprovalSettingType

type approvalSettingsType = {
  connectionCreation: approvalSettingType
  connectionUpdate: approvalSettingType
  enclaveEndpointUpdate: approvalSettingType
  enclaveMaintenanceMode: approvalSettingType
}

@description('Name of the Mission virtual enclave whose approval settings should be activated.')
@minLength(1)
param enclaveName string

@description('Final desired Mission approval settings to activate after workload deployment succeeds.')
param desiredApprovalSettings approvalSettingsType

var normalizedDesiredApprovalSettings = {
  connectionCreation: desiredApprovalSettings.connectionCreation.approvalPolicy == 'Required'
    ? {
        approvalPolicy: 'Required'
        mandatoryApprovers: desiredApprovalSettings.connectionCreation.mandatoryApprovers
        minimumApproversRequired: desiredApprovalSettings.connectionCreation.minimumApproversRequired
      }
    : {
        approvalPolicy: 'NotRequired'
        mandatoryApprovers: []
        minimumApproversRequired: 0
      }
  connectionUpdate: desiredApprovalSettings.connectionUpdate.approvalPolicy == 'Required'
    ? {
        approvalPolicy: 'Required'
        mandatoryApprovers: desiredApprovalSettings.connectionUpdate.mandatoryApprovers
        minimumApproversRequired: desiredApprovalSettings.connectionUpdate.minimumApproversRequired
      }
    : {
        approvalPolicy: 'NotRequired'
        mandatoryApprovers: []
        minimumApproversRequired: 0
      }
  enclaveEndpointUpdate: desiredApprovalSettings.enclaveEndpointUpdate.approvalPolicy == 'Required'
    ? {
        approvalPolicy: 'Required'
        mandatoryApprovers: desiredApprovalSettings.enclaveEndpointUpdate.mandatoryApprovers
        minimumApproversRequired: desiredApprovalSettings.enclaveEndpointUpdate.minimumApproversRequired
      }
    : {
        approvalPolicy: 'NotRequired'
        mandatoryApprovers: []
        minimumApproversRequired: 0
      }
  enclaveMaintenanceMode: desiredApprovalSettings.enclaveMaintenanceMode.approvalPolicy == 'Required'
    ? {
        approvalPolicy: 'Required'
        mandatoryApprovers: desiredApprovalSettings.enclaveMaintenanceMode.mandatoryApprovers
        minimumApproversRequired: desiredApprovalSettings.enclaveMaintenanceMode.minimumApproversRequired
      }
    : {
        approvalPolicy: 'NotRequired'
        mandatoryApprovers: []
        minimumApproversRequired: 0
      }
}

resource approvalActivationDeployment 'Microsoft.Resources/deployments@2022-09-01' = {
  name: 'missionEnclaveApprovalActivation'
  properties: {
    expressionEvaluationOptions: {
      scope: 'inner'
    }
    mode: 'Incremental'
    parameters: {
      desiredApprovalSettings: {
        value: normalizedDesiredApprovalSettings
      }
      enclaveName: {
        value: enclaveName
      }
    }
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        desiredApprovalSettings: {
          type: 'object'
        }
        enclaveName: {
          type: 'string'
        }
      }
      variables: {
        liveEnclave: '''
[reference(resourceId('Microsoft.Mission/virtualEnclaves', parameters('enclaveName')), '2026-03-01-preview', 'Full')]
'''
        existingSubnetConfigurations: '''
[map(variables('liveEnclave').properties.enclaveVirtualNetwork.subnetConfigurations, lambda('subnet', if(empty(lambdaVariables('subnet').subnetDelegation), createObject('networkPrefixSize', lambdaVariables('subnet').networkPrefixSize, 'subnetName', lambdaVariables('subnet').subnetName), createObject('networkPrefixSize', lambdaVariables('subnet').networkPrefixSize, 'subnetDelegation', lambdaVariables('subnet').subnetDelegation, 'subnetName', lambdaVariables('subnet').subnetName))))]
'''
        enclaveVirtualNetwork: '''
[union(createObject('allowSubnetCommunication', bool(variables('liveEnclave').properties.enclaveVirtualNetwork.allowSubnetCommunication), 'subnetConfigurations', variables('existingSubnetConfigurations')), if(empty(variables('liveEnclave').properties.enclaveVirtualNetwork.customCidrRange), createObject('networkSize', variables('liveEnclave').properties.enclaveVirtualNetwork.networkSize), createObject('customCidrRange', variables('liveEnclave').properties.enclaveVirtualNetwork.customCidrRange, 'networkSize', 'custom')), if(empty(variables('liveEnclave').properties.enclaveVirtualNetwork.networkName), createObject(), createObject('networkName', variables('liveEnclave').properties.enclaveVirtualNetwork.networkName)))]
'''
        updatedProperties: '''
[union(createObject('bastionEnabled', bool(variables('liveEnclave').properties.bastionEnabled), 'communityResourceId', variables('liveEnclave').properties.communityResourceId, 'enclaveDefaultSettings', createObject('diagnosticDestination', string(variables('liveEnclave').properties.enclaveDefaultSettings.diagnosticDestination)), 'enclaveVirtualNetwork', variables('enclaveVirtualNetwork'), 'approvalSettings', parameters('desiredApprovalSettings'), 'rbacInheritance', variables('liveEnclave').properties.rbacInheritance, 'workloadResourceVisibility', variables('liveEnclave').properties.workloadResourceVisibility), if(empty(variables('liveEnclave').properties.dedicatedHubResourceId), createObject(), createObject('dedicatedHubResourceId', variables('liveEnclave').properties.dedicatedHubResourceId)), if(empty(variables('liveEnclave').properties.enclaveRoleAssignments), createObject(), createObject('enclaveRoleAssignments', variables('liveEnclave').properties.enclaveRoleAssignments)), if(empty(variables('liveEnclave').properties.governedServiceList), createObject(), createObject('governedServiceList', variables('liveEnclave').properties.governedServiceList)), if(empty(variables('liveEnclave').properties.maintenanceModeConfiguration), createObject(), createObject('maintenanceModeConfiguration', variables('liveEnclave').properties.maintenanceModeConfiguration)), if(empty(variables('liveEnclave').properties.monitoringSettings), createObject(), createObject('monitoringSettings', variables('liveEnclave').properties.monitoringSettings)), if(empty(variables('liveEnclave').properties.workloadRoleAssignments), createObject(), createObject('workloadRoleAssignments', variables('liveEnclave').properties.workloadRoleAssignments)))]
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
        enclaveResourceId: {
          type: 'string'
          value: '''
[resourceId('Microsoft.Mission/virtualEnclaves', parameters('enclaveName'))]
'''
        }
      }
    }
  }
}

output enclaveResourceId string = approvalActivationDeployment.properties.outputs.enclaveResourceId.value
