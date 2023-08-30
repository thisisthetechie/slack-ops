Param(
  [string]$output
)

##########################################################
## Convert Pipeline Variables
##########################################################
$request_variables  = $env:REQUEST_PARAMETERS | ConvertFrom-Json
$subscription_name  = $env:REQUEST_PARAMETERS.subscription
$project_short_name = $env:REQUEST_PARAMETERS.project_short_name
$locations          = "${env:REQUEST_PARAMETERS.locations},"
$organization       = $env:REQUEST_PARAMETERS.organization

$subscription       = [Environment]::GetEnvironmentVariable($subscription_name.ToUpper()) | ConvertFrom-Json

Write-Host "Request Parameters: $request_variables"

##########################################################
## Generate Tags
##########################################################
$tags = @{
  # Map of tags to be applied to all Resources
  "cost code"         = $env:REQUEST_PARAMETERS.cost_code
  "subscription"       = $subscriptions.$subscription_name
  "product"           = $env:REQUEST_PARAMETERS.project_name
  "product owner"     = $env:REQUEST_PARAMETERS.product_owner
  "requested by"      = $env:REQUEST_PARAMETERS.requested_by
  "support-team"      = $env:REQUEST_PARAMETERS.team_name
}

##########################################################
## Variables
##########################################################
$storage_account_sku = "Standard_LRS"
$storage_account_kind = "StorageV2"
$storage_container_name = "tfstate"

##########################################################
## Basic Function for creating resource group
##########################################################
function create_resource_group {
  param(
    [string]$resource_group
  )

  Write-Host "Attempting to create ${resource_group}"

  # Check for existing Resource Group
  if ( $( Get-AzResourceGroup | Where-Object { $_.ResourceGroupName -eq $resource_group}  ).count -gt 1 ) {
    $output += "Resource group ${resource_group} already exists!|"
    Return "Resource group ${resource_group} already exists!"

  } else {

    try {
      # Create Resource Group
      New-AzResourceGroup -Name $resource_group -Location $location -Tags $tags
      $output += "Created Resource Group ${resource_group}|"
      Return "Created Resource Group ${resource_group}"
      
    } catch {

      throw $_

    }
  }
}

##########################################################
## Basic Function for creating storage account
##########################################################
function create_storage_account {
  param(
    [string]$storage_account_name,
    [string]$resource_group,
    [string]$location
  )

  Write-host "Attempting to create ${storage_account} in ${resource_group}"

  # Check for existing Storage Account in Resource Group
  if ( $( az storage account list --resource-group $resource_group --query "[?name=='$storage_account']" ).count -gt 1 ) {
    Return "Terraform Storage Account ${storage_account} already exists in ${resource_group}"

  } else {
    try {
      # Create Storage Account in existing Resource Group
      $storage_account = $(New-AzStorageAccount -ResourceGroupName $resource_group -Name $storage_account  -Location $location -SkuName $storage_account_sku -Kind $storage_account_kind)
      New-AzStorageContainer -Name $storage_container_name -Context $storage_account.Context -Permission Container
      $output += "Created ${storage_account} in ${resource_group} for Terraform State Files|"
      Return "Created ${storage_account} in ${resource_group}"

    } catch {
      
      Throw $_

    }
  } 
}

##########################################################
## Create Resource Group(s)
##########################################################
try {
  Write-Host "logging in..."
  Set-AzContext $subscription_name

  $resource_groups = $null
  # Loop the locations
  foreach ( $location in $( $locations.split(",") | Select-Object -SkipLast 1 ) ) {
    $location_shortname = [Environment]::GetEnvironmentVariable($location.ToUpper())
    $resource_group = "${organization}-${project_short_name}-rg-$($subscription.shortname)-${location_shortname}"
    $resource_groups += "${resource_group},"

    # Create Resource Group
    Write-Host $(create_resource_group -resource_group $resource_group)

    # Create Storage Account
    Write-Host $(create_storage_account -storage_account $terraform_storage -resource_group $resource_group -location $location_shortname)
  }

} catch {

  # Otherwise, we need to report failure
  Write-Host "Failed to create ${resource_group}:"
  Write-Host $_
  Throw

} finally {

  ##########################################################
  ## Check to see if a Service Connection is required
  ##########################################################
  if ($env:REQUEST_PARAMETERS.create_service_connection -eq "True") {
    Write-Host "##vso[task.setvariable variable=create_service_connection]$True"
    Write-Host "##vso[task.setvariable variable=resources]$resource_groups"
  }

  ##########################################################
  ## Return Outputs
  ##########################################################
  Write-Host "##vso[task.setvariable variable=output]$output"
}

