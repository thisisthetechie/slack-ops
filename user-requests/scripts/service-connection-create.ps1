Param(
  [string]$output
)

##########################################################
## Convert Pipeline Variables
##########################################################
$request_variables  = $env:REQUEST_PARAMETERS | ConvertFrom-Json
$subscription_name  = $env:REQUEST_PARAMETERS.subscription
$project_short_name = $env:REQUEST_PARAMETERS.project_short_name
$azdo_project_name  = $env:REQUEST_PARAMETERS.azure_project_name
$organization       = $env:REQUEST_PARAMETERS.organization

$subscription       = [Environment]::GetEnvironmentVariable($subscription_name.ToUpper()) | ConvertFrom-Json

Write-Host "Request Parameters: $request_variables"
 
## Azure DevOps Authentication Headers
$headers = @{
  Authorization = "Basic ${env:SYSTEM_ACCESSTOKEN}"
}

##########################################################
## Basic Function for creating Service Principal
##########################################################
function create_service_principal {
  param(
    [string]$service_principal_name,
    [string]$permissions,
    [string]$scope
  )

  try {
    $result = $(New-AzADServicePrincipal -DisplayName $service_principal_name)
    $output += "Created Service Principal ${service_principal_name}|"
    Return $result

  } catch {
    Throw $_
  }
}
##########################################################
## Basic Function for getting AzDo Project IDs
##########################################################
function get_azdo_project_id {
  param(
    [string]$azdo_project_name
  )

  $url = "${env:SYSTEM_TEAMFOUNDATIONSERVERURI}_apis/projects?api-version=6.0"

  try {

    # Get the Project Details
    $project = $(Invoke-RestMethod -Uri $url -Headers $headers)
    Return $project.id
  } catch {
    Return $null
  }
}

##########################################################
## Basic Function for creating Service Connection
##########################################################
function create_azdo_service_connection {
  param(
    [string]$service_connection_name,
    [string]$azdo_project_name,
    [string]$service_principal_id,
    [string]$service_principal_secret
  )

  $project_url = "${env:SYSTEM_TEAMFOUNDATIONSERVERURI}${$azdo_project_name}/_apis/serviceendpoint/endpoints?api-version=6.0-preview.4"
  $project_id = $(get_azdo_project_id -azdo_project_name $service_connection_name)
  if ($null -ne $project_id) {

    Write-Host "Project ID: ${project_id}"

    ##########################################################
    ## Create Request Body for new Service Connection
    ##########################################################
    $request_body  = @{
      data = @{
          subscriptionId   = $subscription_id
          subscriptionName = $subscription
          subscription      = "AzureCloud"
          scopeLevel       = "Subscription"
          creationMode     = "Manual"
      }
      name = ($subscription -replace " ")
      type = "AzureRM"
      url  = "https://management.azure.com/"
      authorization = @{
        parameters = @{
            tenantid            = $tenant_id
            serviceprincipalid  = $service_principal_id
            authenticationType  = "spnKey"
            serviceprincipalkey = $service_principal_secret
        }
        scheme = "ServicePrincipal"
      }
      isShared = $false
      isReady  = $true
      serviceEndpointProjectReferences = @(
        @{
          projectReference = @{
            id   = $project_id
            name = $azdo_project_name
          }
        name = $service_connection_name
        }
      )
    } | ConvertTo-Json -Depth 99

    Invoke-RestMethod -Uri $project_url -Method "POST" -Body $request_body -Headers $headers -ContentType = "application/json"
    $output += "Created Service Connection ${service_connection_name} on Project ${project_name}|"
    Return "Created Service Connection ${service_connection_name} on Project ${project_name}"

  } catch {
    $output += "Azure Project ${project_name} could not be found!|"
    Return "Azure Project ${project_name} could not be found!"
  }

}
##########################################################
## Create Service Connection
##########################################################
try {
  Write-Host "logging in..."
  $subscription_context = $(Set-AzContext $subscription_name)
  $subscription_id = $subscription_context.Subscription.Id 
  $tenant_id = $subscription_context.Subscription.TenantId 

  $service_connection_name = "${organization}-${project_short_name}-rg-$($subscription.shortname)"
  $permissions = "Contributor"
  
  
  Write-Host "Attempting to create ${service_connection_name}"
  $service_principal = $(New-AzADServicePrincipal -DisplayName $service_connection_name)
  $output += "Created Service Principal ${service_connection_name}|"

  Write-Host "Attempting to connect Service Principal to ${azdo_project_name}"
  Write-host $(create_azdo_service_connection -service_connection_name $service_connection_name -azdo_project_name $azdo_project_name -service_principal_id $service_principal.Id -service_principal_secret $service_principal.PasswordCredentials.SecretText)

} catch {

  # Otherwise, we need to report failure
  Throw "Failed to create ${service_connection_name}:`n$_"

} finally {

  ##########################################################
  ## Return Outputs
  ##########################################################
  Write-Host "##vso[task.setvariable variable=output]$output"
  Write-Host "##vso[task.setvariable variable=service_connection_name]$service_connection_name"

}

