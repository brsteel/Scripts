targetScope = 'subscription'

param location string = deployment().location

var tags = {
  environment: 'example'
  workload: 'postgresql-existing'
}

module phaseA '../avePostgreSqlEnclaveDeployment.bicep' = {
  name: 'existingCompatiblePhaseA'
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
      mode: 'existing'
      resourceId: '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mission-enclave/providers/Microsoft.Mission/virtualEnclaves/existing-enclave'
      expectedConfiguration: {
        approvalPolicies: {
          connectionCreation: 'Required'
          connectionUpdate: 'Required'
          enclaveEndpointUpdate: 'Required'
          enclaveMaintenanceMode: 'Required'
        }
        communityResourceId: '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mission-community/providers/Microsoft.Mission/communities/existing-community'
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
          allowSubnetCommunication: 'Disabled'
          delegatedSubnet: {
            addressPrefix: '10.250.10.0/24'
            name: 'snet-postgresql'
            networkPrefixSize: 24
            networkSecurityGroupResourceId: '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mission-managed/providers/Microsoft.Network/networkSecurityGroups/nsg-postgresql'
            resourceId: '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mission-managed/providers/Microsoft.Network/virtualNetworks/vnet-existing-enclave/subnets/snet-postgresql'
            subnetDelegation: 'Microsoft.DBforPostgreSQL/flexibleServers'
          }
          privateEndpointSubnet: {
            addressPrefix: '10.250.20.0/24'
            name: 'snet-private-endpoints'
            networkPrefixSize: 24
            networkSecurityGroupResourceId: '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mission-managed/providers/Microsoft.Network/networkSecurityGroups/nsg-private-endpoints'
            resourceId: '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mission-managed/providers/Microsoft.Network/virtualNetworks/vnet-existing-enclave/subnets/snet-private-endpoints'
            subnetDelegation: ''
          }
        }
        rbacInheritance: 'Disabled'
        workloadResourceVisibility: 'Disabled'
      }
    }
    foundation: {
      cmkIdentity: {
        mode: 'existing'
        resourceId: '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-workload/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uai-postgresql-cmk'
        expectedConfiguration: {
          clientId: '33333333-3333-3333-3333-333333333333'
          location: location
          principalId: '44444444-4444-4444-4444-444444444444'
        }
      }
      key: {
        mode: 'existing'
        resourceId: '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-workload/providers/Microsoft.KeyVault/vaults/kvexisting/keys/postgresql-cmk'
        expectedConfiguration: {
          enabled: 'Enabled'
          keySize: 3072
          keyType: 'RSA-HSM'
          versionlessKeyUri: 'https://kvexisting.vault.azure.net/keys/postgresql-cmk'
        }
      }
      keyVault: {
        mode: 'existing'
        resourceId: '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-workload/providers/Microsoft.KeyVault/vaults/kvexisting'
        expectedConfiguration: {
          location: location
          networkBypass: 'None'
          networkDefaultAction: 'Deny'
          publicNetworkAccess: 'Disabled'
          purgeProtection: 'Enabled'
          rbacAuthorization: 'Enabled'
          skuName: 'premium'
          softDeleteRetentionDays: 90
          tenantId: tenant().tenantId
        }
      }
      privateDns: {
        delegatedZone: {
          mode: 'existing'
          resourceId: '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-workload/providers/Microsoft.Network/privateDnsZones/ave-example.postgres.database.azure.com'
          expectedName: 'ave-example.postgres.database.azure.com'
        }
        keyVaultPrivateLinkZone: {
          mode: 'existing'
          resourceId: '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-workload/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net'
          expectedName: 'privatelink.vaultcore.azure.net'
        }
      }
    }
    workload: {
      mode: 'managed'
      name: 'pgworkload02'
      resourceGroupName: 'rg-contoso-existing-postgresql-workload'
    }
  }
}

module phaseB '../avePostgreSqlEnclaveNetworkFinalization.bicep' = {
  name: 'existingCompatiblePhaseB'
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
  name: 'existingCompatiblePhaseC'
  params: {
    deploymentContext: {
      location: location
      tags: tags
    }
    foundation: phaseB.outputs.foundation
    server: {
      mode: 'existing'
      resourceId: '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-contoso-existing-postgresql-workload/providers/Microsoft.DBforPostgreSQL/flexibleServers/existing-postgresql'
      expectedConfiguration: {
        activeDirectoryAuth: 'Enabled'
        administrators: [
          {
            objectId: '22222222-2222-2222-2222-222222222222'
            principalName: 'dba-group@contoso.example'
            principalType: 'Group'
            tenantId: tenant().tenantId
          }
        ]
        backup: {
          geoRedundancy: 'Disabled'
          retentionDays: 35
        }
        cmkIdentityResourceId: '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-workload/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uai-postgresql-cmk'
        cmkKeyUri: 'https://kvexisting.vault.azure.net/keys/postgresql-cmk'
        configurations: []
        databases: [
          {
            name: 'appdb'
          }
        ]
        delegatedSubnetResourceId: '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mission-managed/providers/Microsoft.Network/virtualNetworks/vnet-existing-enclave/subnets/snet-postgresql'
        deletionLock: 'CanNotDelete'
        diagnostics: {
          mode: 'Absent'
        }
        highAvailability: {
          mode: 'Disabled'
        }
        location: location
        maintenanceWindow: {
          mode: 'SystemManaged'
        }
        passwordAuth: 'Disabled'
        privateDnsZoneResourceId: '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-workload/providers/Microsoft.Network/privateDnsZones/ave-example.postgres.database.azure.com'
        sku: {
          name: 'Standard_D4ds_v5'
          tier: 'GeneralPurpose'
        }
        storage: {
          storageSizeGB: 128
          type: 'Premium_LRS'
        }
        tenantId: tenant().tenantId
        version: '16'
      }
    }
  }
}

output phaseAContract string = phaseA.outputs.contractVersion
output phaseBContract string = phaseB.outputs.contractVersion
output phaseCContract string = phaseC.outputs.contractVersion
