##########################################################
## Convert Pipeline Variables
##########################################################
$user              = $env:VAR_USER
$key_vault         = $env:VAR_KEY_VAULT
$resource_group    = $env:VAR_RESOURCE_GROUP
$change_request    = $env:VAR_CHANGE_REQUEST
$date_required     = $env:VAR_DATE_REQUIRED
$request_reason    = $env:VAR_REQUEST_REASON
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

  # Get date information
  $fmtDate = Select-String "(\d{1,2})\/(\d{1,2})\/(\d{2,4})" -InputObject $date_required
  $date_required = Get-Date '{0}/{1}/{2}' -f $fmtDate.Matches.groups[2], $fmtDate.Matches.groups[1], $fmtDate.Matches.groups[3]

  if ( $date_required -gt $(Get-Date) ) {
    $added = 'null'
    $status = 'Scheduled'
  } else {
    $added = get-date -Format "dd/MM/yyyy HH:mm"
    $status = 'Added'

    Write-Host "Adding Access Policy for ${user} on ${key_vault}"
    Set-AzKeyVaultAccessPolicy -VaultName $key_vault  -UserPrincipalName $user -PermissionsToKeys get,list,create,update,delete -PermissionsToSecrets set,delete,get,list
    $output += "Added Access Policy for ${user} on ${key_vault}`n"
    
    Write-Host "Adding Role Assignment for ${user} on ${key_vault}"
    New-AzRoleAssignment -SignInName $user -RoleDefinitionName "Reader" -resourcegroupname $resource_group
    $output += "Added Role Assignment for ${user} on ${resource_group}`n"
  }

  Write-Host "Adding details to access_register"
  # But first, set a "Temporary" flag if this is for a Production KeyVault
  if ($subscription -eq "production") {
    $temporary = "True"
  } else {
    $temporary = "False"
  }
 
  $register = @{
    ChangeRequest = $change_request
    User          = $user
    ResourceGroup = $resource_group
    Resource      = $key_vault
    DateRequired  = $date_required
    Added         = $added
    Removed       = 'null'
    Status        = $status
    Reason        = $request_reason
    Temporary     = $temporary
  }

  Add-AzTableRow -Table $table -PartitionKey KeyVault -RowKey $env.BUILD_BUILDID -Property $register

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

