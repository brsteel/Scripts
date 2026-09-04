targetScope = 'resourceGroup'

@description('Name of the existing Microsoft Mission virtual enclave that owns the workload registration.')
@minLength(1)
param enclaveName string

@description('Name of the existing Mission workload registration.')
@minLength(1)
param workloadName string

resource enclaveResource 'Microsoft.Mission/virtualEnclaves@2026-03-01-preview' existing = {
  name: enclaveName
}

resource workloadResource 'Microsoft.Mission/virtualEnclaves/workloads@2026-03-01-preview' existing = {
  parent: enclaveResource
  name: workloadName
}

output resourceId string = workloadResource.id
output resourceGroupCollection string[] = workloadResource.properties.resourceGroupCollection
