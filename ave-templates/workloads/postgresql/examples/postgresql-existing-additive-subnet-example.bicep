targetScope = 'subscription'

param location string = deployment().location

var tags = {
  environment: 'example'
  workload: 'postgresql-existing-additive'
}

module phaseA '../avePostgreSqlEnclaveDeployment.bicep' = {
  name: 'existingAdditivePhaseA'
  params: {
    community: {
      mode: 'existing'
      resourceId: '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mission-community/providers/Microsoft.Mission/communities/existing-community'
    }
    deploymentContext: {
      location: location
      tags: tags
    }
    deploymentPrincipal: {
      objectId: '11111111-1111-1111-1111-111111111111'
      principalType: 'User'
    }
    enclave: {
      mode: 'AdditiveSubnetUpdate'
      resourceId: '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mission-enclave/providers/Microsoft.Mission/virtualEnclaves/existing-enclave'
      expectedConfiguration: {
        approvalSettings: {
          connectionCreation: {
            approvalPolicy: 'Required'
            mandatoryApprovers: [
              {
                approverEntraId: '55555555-5555-5555-5555-555555555555'
              }
            ]
            minimumApproversRequired: 1
          }
          connectionUpdate: {
            approvalPolicy: 'Required'
            mandatoryApprovers: [
              {
                approverEntraId: '66666666-6666-6666-6666-666666666666'
              }
            ]
            minimumApproversRequired: 1
          }
          enclaveEndpointUpdate: {
            approvalPolicy: 'Required'
            mandatoryApprovers: [
              {
                approverEntraId: '77777777-7777-7777-7777-777777777777'
              }
            ]
            minimumApproversRequired: 1
          }
          enclaveMaintenanceMode: {
            approvalPolicy: 'Required'
            mandatoryApprovers: [
              {
                approverEntraId: '88888888-8888-8888-8888-888888888888'
              }
            ]
            minimumApproversRequired: 1
          }
        }
        bastionEnabled: 'Enabled'
        communityResourceId: '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mission-community/providers/Microsoft.Mission/communities/existing-community'
        diagnosticDestination: 'Both'
        governedServiceList: [
          {
            enforcement: 'Enabled'
            option: 'Allow'
            policyAction: 'Enforce'
            serviceId: 'KeyVault'
          }
          {
            enforcement: 'Enabled'
            option: 'Allow'
            policyAction: 'Enforce'
            serviceId: 'PostgreSQL'
          }
          {
            enforcement: 'Enabled'
            option: 'Allow'
            policyAction: 'Enforce'
            serviceId: 'PrivateDNSZones'
          }
        ]
        location: location
        network: {
          allowSubnetCommunication: 'Enabled'
        }
        rbacInheritance: 'Disabled'
        workloadResourceVisibility: 'Disabled'
      }
      postgreSqlSubnet: {
        name: 'snet-postgresql-workload02'
        networkPrefixSize: 24
      }
      privateEndpointSubnet: {
        mode: 'New'
        name: 'snet-private-endpoints-workload02'
        networkPrefixSize: 24
      }
    }
    foundation: {
      cmkIdentity: {
        mode: 'managed'
      }
      key: {
        mode: 'managed'
      }
      keyVault: {
        mode: 'managed'
      }
      privateDns: {
        delegatedZone: {
          mode: 'managed'
        }
        keyVaultPrivateLinkZone: {
          mode: 'managed'
        }
      }
    }
    workload: {
      mode: 'managed'
      name: 'pgworkload03'
      resourceGroupName: 'rg-contoso-existing-additive-postgresql-workload'
    }
  }
}

module phaseB '../avePostgreSqlEnclaveNetworkFinalization.bicep' = {
  name: 'existingAdditivePhaseB'
  params: {
    deploymentContext: {
      tags: tags
    }
    networkFinalization: {
      mode: 'ExistingReferenceOnly'
      communityEndpointResourceIds: [
        '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mission-community/providers/Microsoft.Mission/communities/existing-community/communityEndpoints/ce-postgresql'
      ]
      enclaveConnectionResourceIds: [
        '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mission-enclave/providers/Microsoft.Mission/enclaveConnections/conn-postgresql'
      ]
    }
    phaseA: phaseA.outputs.phaseA
  }
}

module phaseC '../avePostgreSqlWorkloadDeployment.bicep' = {
  name: 'existingAdditivePhaseC'
  params: {
    deploymentContext: {
      location: location
      tags: tags
    }
    foundation: phaseB.outputs.foundation
    server: {
      mode: 'managed'
      version: '16'
      sku: {
        name: 'Standard_D4ds_v5'
        tier: 'GeneralPurpose'
      }
      administrators: [
        {
          objectId: '22222222-2222-2222-2222-222222222222'
          principalName: 'dba-group@contoso.example'
          principalType: 'Group'
          tenantId: tenant().tenantId
        }
      ]
    }
  }
}

output phaseAContract string = phaseA.outputs.contractVersion
output phaseBContract string = phaseB.outputs.contractVersion
output phaseCContract string = phaseC.outputs.contractVersion
