Param(
  [string]$output
)

##########################################################
## Convert Pipeline Variables
##########################################################
$request_variables = $env:REQUEST_PARAMETERS | ConvertFrom-Json
$key_vault = $request_variables.key_vault
$subscription = $request_variables.subscription
$location  = $request_variables.location

Write-Host "Request Parameters: $request_variables"

##########################################################
## Purge Key Vault
##########################################################
try {
  Write-Host "logging in..."
  $subscription_id = $(Set-AzContext $subscription).subscription

  Write-Host "Locating ${key_vault} in ${subscription} ${location}"
  $key_vault_object = Get-AzKeyVault -InRemovedState -SubscriptionId $subscription_id -VaultName $key_vault -Location $location

  if ($key_vault_object.count -eq 1) {
    Write-Host "Purging ${key_vault} Key Vault: " -NoNewline
    Remove-AzKeyVault -VaultName $key_vault -InRemovedState -Force -Location "Location" -PassThru
    $output += "Purged ${key_vault} in ${subscription} ${location}"
  } else {
    $output += "Unable to locate ${key_vault} for purging in ${subscription} ${location}"
  }

} catch {

  # Otherwise, we need to report failure
  Write-Host "Failed to purge ${key_vault}:"
  Write-Host $_
  Throw

} finally {

  ##########################################################
  ## Return Outputs
  ##########################################################
  Write-Host "##vso[task.setvariable variable=output]$output"
}

