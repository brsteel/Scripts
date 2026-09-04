targetScope = 'resourceGroup'

@description('Name of the existing Microsoft Mission virtual enclave that owns the workload registration.')
@minLength(1)
param enclaveName string

@description('Mission workload registration name.')
@minLength(1)
@maxLength(30)
param name string

@description('Azure region for the workload registration.')
@minLength(1)
param location string

@description('Resource group IDs governed by this Mission workload registration.')
param resourceGroupCollection string[]

@description('Tags applied to the workload registration.')
param tags object = {}

resource enclaveResource 'Microsoft.Mission/virtualEnclaves@2026-03-01-preview' existing = {
  name: enclaveName
}

resource workloadResource 'Microsoft.Mission/virtualEnclaves/workloads@2026-03-01-preview' = {
  parent: enclaveResource
  name: name
  location: location
  tags: tags
  properties: {
    resourceGroupCollection: resourceGroupCollection
  }
}

output resourceId string = workloadResource.id
output resourceName string = workloadResource.name
output resourceGroupCollection string[] = workloadResource.properties.resourceGroupCollection
