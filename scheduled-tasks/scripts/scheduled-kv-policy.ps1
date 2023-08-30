##########################################################
## Convert Pipeline Variables
##########################################################
$user              = $env:VAR_USER
$key_vault         = $env:VAR_KEY_VAULT
$resource_group    = $env:VAR_RESOURCE_GROUP
$storage_account   = $env:STORAGE_ACCOUNT


##########################################################
## Add Service Connection to Role
##########################################################
try {
  Write-Host "logging in..."
  Set-AzContext $subscription 

  Write-Host "Getting Access Request Table"
  $storageAccount = Get-AzStorageAccount -Name $storage_account -ResourceGroupName $resource_group
  $table = (Get-AzStorageTable -Name 'keyVaultAccess' -Context $storageAccount.Context).CloudTable

  Write-Host "Getting Scheduled Access Requests"
  $scheduled_requests = Get-AzTableRow -Table $table -CustomFilter "(PartitionKey eq 'KeyVault' and Status eq 'Scheduled')"

  foreach ( $request in $scheduled_requests ) {
    if ( $request.DateRequired -le $(Get-Date) ) {

      $added = get-date -Format "dd/MM/yyyy HH:mm"
      $status = 'Added'

      Write-Host "Adding Access Policy for  ${request.Name} on ${request.Resource}"
      Set-AzKeyVaultAccessPolicy -VaultName $request.Resource  -UserPrincipalName $request.Name -PermissionsToKeys get,list,create,update,delete -PermissionsToSecrets set,delete,get,list
      $output += "Added Access Policy for  ${request.Name} on ${request.Resource}`n"
      
      Write-Host "Adding Role Assignment for ${request.Name} on ${request.Resource}"
      New-AzRoleAssignment -SignInName $request.Name -RoleDefinitionName "Reader" -resourcegroupname $resource_group
      $output += "Added Role Assignment for  ${request.Name} on ${request.Resource}`n"

      Write-Host "Updating Register"
      $request.Added = $added
      $request.Status  = $status
      $request | Update-AzTableRow -table $table
    }
  }

} catch {

  # Otherwise, we need to report failure
  Write-Host "An error occured trying to add access policy for ${user} on ${key_vault}:`n$_"

} finally {

  ##########################################################
  ## Return Outputs
  ##########################################################
  Write-Host "##vso[task.setvariable variable=comments;isoutput=true]$output"
  Write-Host "Output: $output"
}

