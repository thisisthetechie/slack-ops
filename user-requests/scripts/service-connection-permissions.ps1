Param(
  [string]$output,
  [string]$service_connection_name = $env:REQUEST_PARAMETERS.service_connection_name,
  [string]$resources = $env:REQUEST_PARAMETERS.resources,
  [string]$permission_level = $env:REQUEST_PARAMETERS.permission_level
)

##########################################################
## Convert Pipeline Variables
##########################################################
$request_variables  = $env:REQUEST_PARAMETERS | ConvertFrom-Json
$subscription_name  = $env:REQUEST_PARAMETERS.subscription

Write-Host "Request Parameters: $request_variables"


##########################################################
## Add Permissions
##########################################################
try {
  Write-Host "logging in..."
  #Connect-AzAccount -Credential $session_credential
  Set-AzContext $subscription_name

  foreach ($resource in $resources) {
    $scope = $(Get-AzResource -name $resource)
    $groups = Get-AzRoleAssignment -RoleDefinitionName $permission_level -Scope $scope.ResourceId | Where-Object -FilterScript { $_.objecttype -match "ServicePrincipal" }
    $scope.ResourceId
    if ($groups.displayname -match $service_connection_name) {
      $output += "Service Principal ${service_connection_name} already has ${permission_level} permissions on ${resource}`n"
    } else {  
      $service_connection = Get-AzADServicePrincipal -DisplayName $service_connection_name
      New-AzRoleAssignment -RoleDefinitionName $permission_level -ApplicationId $service_connection.AppId -Scope $scope.ResourceId
      $output += "Added ${service_connection_name} as ${permission_level} on ${resource}`n"
    }
  }

} catch {

  # Otherwise, we need to report failure
  Throw "Failed to add ${permission_level} permissions to ${service_connection_name}:`n$_"

} finally {

  ##########################################################
  ## Return Outputs
  ##########################################################
  Write-Host "##vso[task.setvariable variable=output]$output"
}

