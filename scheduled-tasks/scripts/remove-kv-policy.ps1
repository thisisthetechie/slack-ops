##########################################################
## Convert Pipeline Variables
##########################################################
$resource_group    = $env:VAR_RESOURCE_GROUP
$storage_account   = $env:STORAGE_ACCOUNT


##########################################################
## Add Service Connection to Role
##########################################################
try {
  Write-Host "Logging in..."
  Set-AzContext $subscription 

  Write-Host "Getting Access Request Table"
  $storageAccount = Get-AzStorageAccount -Name $storage_account -ResourceGroupName $resource_group
  $table = (Get-AzStorageTable -Name 'AccessRegister' -Context $storageAccount.Context).CloudTable

  Write-Host "Getting Expired Access Requests"
  $expired_requests = Get-AzTableRow -Table $table -CustomFilter "(PartitionKey eq 'KeyVault' and Added ne 'null' and Removed eq 'null' and Temporary eq 'True')"

  foreach ($access in $expired_requests) {
    Write-Host "Removing Access Policy for ${access.Name} on ${access.Resource}"
    Remove-AzKeyVaultAccessPolicy -VaultName $access.Resource -UserPrincipalName $access.Name 
    $output += "Removed Access Policy for ${access.Name} on ${access.Resource}`n"
    
    Write-Host "Removing Role Assignment for ${access.Name} on ${access.Resource}"
    Remove-AzRoleAssignment -SignInName $access.Name -RoleDefinitionName "Reader" -resourcegroupname $resource_group
    $output += "Removed Role Assignment for  ${access.Name} on ${access.Resource}`n"

    Write-Host "Updating Register"
    $date = get-date -Format "dd/MM/yyyy HH:mm"
    $access.Removed = $date
    $access.Status  = 'Removed'
    $access | Update-AzTableRow -table $table
  }

} catch {

  # Otherwise, we need to report failure
  Write-Host "An error occured trying to remove access policy:`n$_"

} finally {

  ##########################################################
  ## Return Outputs
  ##########################################################
  Write-Host "##vso[task.setvariable variable=comments;isoutput=true]$output"
  Write-Host "Output: $output"
}

