Param(
  [string]$output
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

  Write-Host "Getting Access Request Table"
  $storageAccount = Get-AzStorageAccount -Name $storage_account -ResourceGroupName $resource_group
  $table = (Get-AzStorageTable -Name 'AccessRegister' -Context $storageAccount.Context).CloudTable

  # Get date information
  $fmtDate = Select-String "(\d{1,2})\/(\d{1,2})\/(\d{2,4})" -InputObject $date_required
  $date_required = Get-Date '{0}/{1}/{2}' -f $fmtDate.Matches.groups[2], $fmtDate.Matches.groups[1], $fmtDate.Matches.groups[3]

  foreach ($resource in $resources) {

    if ( $date_required -gt $(Get-Date) ) {
      $added = 'null'
      $status = 'Scheduled'
    } else {
      $added = get-date -Format "dd/MM/yyyy HH:mm"
      $status = 'Added'
  
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
  
    Write-Host "Adding details to access_register"
    # But first, set a "Temporary" flag if this is for a protected KeyVault
    if ( $subscription -in @("production") ) {
      $temporary = "True"
    } else {
      $temporary = "False"
    }
   
    $register = @{
      ChangeRequest = $change_request
      User          = $user
      ResourceGroup = $resource_group
      Resource      = $resource
      DateRequired  = $date_required
      Added         = $added
      Removed       = 'null'
      Status        = $status
      Reason        = $request_reason
      Temporary     = $temporary
    }
  
    Add-AzTableRow -Table $table -PartitionKey UserPermission -RowKey $env.BUILD_BUILDID -Property $register

  
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

