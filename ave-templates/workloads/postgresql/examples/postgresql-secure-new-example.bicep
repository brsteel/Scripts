targetScope = 'subscription'

param location string = deployment().location

var tags = {
  environment: 'example'
  workload: 'postgresql'
}

module phaseA '../avePostgreSqlEnclaveDeployment.bicep' = {
  name: 'secureNewPhaseA'
  params: {
    community: {
      mode: 'managed'
      name: 'contoso-community'
      resourceGroupName: 'rg-contoso-community'
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
      mode: 'managed'
      name: 'contoso-enclave'
      resourceGroupName: 'rg-contoso-enclave'
      addressSpaceCidr: '10.250.0.0/16'
      postgreSqlSubnet: {
        name: 'snet-postgresql'
        networkPrefixSize: 24
      }
      privateEndpointSubnet: {
        name: 'snet-private-endpoints'
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
      name: 'pgworkload01'
      resourceGroupName: 'rg-contoso-postgresql-workload'
    }
  }
}

module phaseB '../avePostgreSqlEnclaveNetworkFinalization.bicep' = {
  name: 'secureNewPhaseB'
  params: {
    deploymentContext: {
      tags: tags
    }
    networkFinalization: {
      mode: 'Managed'
    }
    phaseA: phaseA.outputs.phaseA
  }
}

module phaseC '../avePostgreSqlWorkloadDeployment.bicep' = {
  name: 'secureNewPhaseC'
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
      storage: {
        storageSizeGB: 128
      }
      backup: {
        retentionDays: 35
      }
      highAvailability: {
        mode: 'ZoneRedundant'
      }
      administrators: [
        {
          objectId: '22222222-2222-2222-2222-222222222222'
          principalName: 'dba-group@contoso.example'
          principalType: 'Group'
          tenantId: tenant().tenantId
        }
      ]
      databases: [
        {
          name: 'appdb'
        }
      ]
      configurations: [
        {
          name: 'azure.extensions'
          value: 'ON'
        }
      ]
    }
  }
}

output phaseAContract string = phaseA.outputs.contractVersion
output phaseBContract string = phaseB.outputs.contractVersion
output phaseCContract string = phaseC.outputs.contractVersion
