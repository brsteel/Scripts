targetScope = 'subscription'

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

type managedGovernanceHardeningType = {
  mode: 'ActivateFinalApprovalSettings'
  approvalSettings: approvalSettingsType
}

type noGovernanceHardeningType = {
  mode: 'NotApplicable'
}

@discriminator('mode')
type governanceHardeningType = managedGovernanceHardeningType | noGovernanceHardeningType

type phaseAType = {
  contractVersion: '3.0'
  enclaveManagedResourceGroupName: string
  enclaveOwnership: 'managed' | 'existing'
  enclaveResourceId: string
  governanceHardening: governanceHardeningType
  targetSubscriptionId: string
}

type workloadCompletionType = {
  flexibleServerResourceId: string
}

@description('Phase A handoff from avePostgreSqlEnclaveDeployment.bicep.')
param phaseA phaseAType

@description('Phase C completion signal used to serialize final approval activation after workload deployment succeeds.')
param workloadCompletion workloadCompletionType

var enclaveName = split(phaseA.enclaveResourceId, '/')[8]

module liveEnclaveState './modules/existingEnclaveStateReader.bicep' = if (phaseA.governanceHardening.mode == 'ActivateFinalApprovalSettings') {
  name: 'postgresqlApprovalActivationLiveState'
  scope: resourceGroup(phaseA.targetSubscriptionId, phaseA.enclaveManagedResourceGroupName)
  params: {
    enclaveName: enclaveName
    postgreSqlSubnetName: ''
    privateEndpointSubnetName: ''
  }
}

module approvalActivationGate './modules/requiredTextSubscriptionGate.bicep' = if (phaseA.governanceHardening.mode == 'ActivateFinalApprovalSettings') {
  name: 'postgresqlApprovalActivationGate'
  params: {
    requiredText: phaseA.enclaveOwnership == 'managed' && liveEnclaveState.outputs.hasExplicitAllowSubnetCommunication && liveEnclaveState.outputs.hasExplicitBastionEnabled && liveEnclaveState.outputs.hasExplicitDiagnosticDestination ? 'compatible' : ''
  }
  dependsOn: [
    liveEnclaveState
  ]
}

module approvalActivation './modules/existingEnclaveApprovalSettingsUpdater.bicep' = if (phaseA.governanceHardening.mode == 'ActivateFinalApprovalSettings') {
  name: 'postgresqlApprovalActivation'
  scope: resourceGroup(phaseA.targetSubscriptionId, phaseA.enclaveManagedResourceGroupName)
  params: {
    enclaveName: enclaveName
    desiredApprovalSettings: phaseA.governanceHardening.approvalSettings
  }
  dependsOn: [
    approvalActivationGate
  ]
}

output contractVersion string = '3.0'
output approvalActivationMode string = phaseA.governanceHardening.mode
output dependentFlexibleServerResourceId string = workloadCompletion.flexibleServerResourceId
output enclaveResourceId string = phaseA.enclaveResourceId
