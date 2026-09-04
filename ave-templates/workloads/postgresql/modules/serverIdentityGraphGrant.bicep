targetScope = 'resourceGroup'

// ──────────────────────────────────────────────────────────────────────────────
// Grants the Microsoft Graph "User.Read.All" application permission to the
// managed PostgreSQL server identity (the user-assigned managed identity used
// for both CMK key access and PostgreSQL's own Microsoft Graph/Entra
// administrator validation calls) through the Microsoft Graph Bicep
// extension (Microsoft.Graph/appRoleAssignedTo@v1.0).
//
// PostgreSQL Flexible Server Entra administrator creation calls Microsoft
// Graph to resolve directory objects. This grant is this template's intended
// permission for that call, applied automatically for managed server
// identities. It is a separate prerequisite from, and not a substitute for,
// the PostgreSQL administrator child resource's own API version/contract;
// see the PostgreSQL workload README "Server identity Microsoft Graph
// prerequisite" section for details.
//
// Deployment identity prerequisite: the principal executing this deployment
// must itself already hold (or be able to exercise, pre-consented by a
// suitably privileged Entra administrator) the Microsoft Graph application
// permissions AppRoleAssignment.ReadWrite.All and Application.Read.All. Azure
// RBAC roles (Owner, Contributor, User Access Administrator, etc.) are not
// sufficient — Microsoft Graph app role assignments are governed exclusively
// by Microsoft Graph permissions, and initial tenant consent cannot be
// self-bootstrapped by this template. See the PostgreSQL workload README for
// the two supported prerequisite paths.
//
// The Microsoft Graph Bicep extension is supported in Azure Government and
// Microsoft Azure operated by 21Vianet in addition to the public cloud, so
// this module does not assume a public-cloud-only Graph endpoint. The
// well-known Microsoft Graph application ID (00000003-0000-0000-c000-000000000000)
// and the well-known User.Read.All application app role ID
// (df021288-bdef-4463-88db-98f22de89214) are constant across clouds.
// ──────────────────────────────────────────────────────────────────────────────

extension microsoftGraphV1

@description('Principal (object) ID of the user-assigned managed identity receiving the Graph app role assignment.')
@minLength(1)
param principalId string

var microsoftGraphAppId = '00000003-0000-0000-c000-000000000000'
var userReadAllAppRoleId = 'df021288-bdef-4463-88db-98f22de89214'

resource microsoftGraphServicePrincipal 'Microsoft.Graph/servicePrincipals@v1.0' existing = {
  appId: microsoftGraphAppId
}

resource userReadAllAssignment 'Microsoft.Graph/appRoleAssignedTo@v1.0' = {
  appRoleId: userReadAllAppRoleId
  principalId: principalId
  resourceId: microsoftGraphServicePrincipal.id
}

output appRoleAssignmentId string = userReadAllAssignment.id
