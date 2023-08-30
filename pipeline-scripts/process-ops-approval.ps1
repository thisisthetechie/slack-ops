

##########################################################
## Set URLs
##########################################################
$response_url = "${env:SYSTEM_TEAMFOUNDATIONSERVERURI}_apis/Contribution/HierarchyQuery/project/${env:SYSTEM_TEAMPROJECT}?api-version=7.0-preview"

##########################################################
## Define Functions 
##########################################################
function api_get() {
## Basic GET Function
  Param (
    [string]$url,
    [string]$token
  )
  $header = @{
    Authorization = 'Bearer ' + $token 
    "Content-Type" = "application/json"
  }
  $request = Invoke-RestMethod -Uri $url -Method get -Headers $header 
  if ($request.ok) {
    Throw
  } else {
    return $request
  }
}

function api_post() {
## Generic POST or PUT Function
  Param (
    [string]$url,
    [string]$token,
    [string]$body,
    [string]$method = "post"
  )
  $header = @{
    Authorization = 'Bearer ' + $token 
    "Content-Type" = "application/json"
  }
  $request = Invoke-RestMethod -Uri $url -Method $method -Headers $header -Body $body
  $request
  if (($request.ok) -or ($request.id -gt 1)) {
    return $request
  } else {
    Write-Host $request
    Throw
  }
}

##########################################################
## Get Intervention data and identify Approval
##########################################################
if ( $env:APPROVAL_REQUIRED -eq "true" ) {
  $release    = api_post -url $response_url -token $env:SYSTEM_ACCESSTOKEN -body $json | ConvertFrom-Json
  $approval_data = $release.dataProviders.'ms.vss-build-web.checks-panel-data-provider'.manualValidations.steps
  $comments = "Approved by $($approval_data.actualApprover.displayName)"
} else {
  # Automatically approved
  $comments = "Automatically Approved"
}

$approved = "True"
Write-Host $comments

##########################################################
## Set internal Job Variable
##########################################################
Write-Host "##vso[task.setvariable variable=approved;isoutput=true]$approved"


