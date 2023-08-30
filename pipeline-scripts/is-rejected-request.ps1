##########################################################
## Set URLs
##########################################################
$response_url = "${env:SYSTEM_TEAMFOUNDATIONSERVERURI}_apis/Contribution/HierarchyQuery/project/${env:SYSTEM_TEAMPROJECT}?api-version=7.0-preview"

##########################################################
## Define Functions 
##########################################################
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
  if ( -not [string]::IsNullOrEmpty($request.dataProviderSharedData) ) {
    return $request
  } else {
    Write-Host $request
    Throw
  }
}

##########################################################
## Payload for getting Approval Details
##########################################################
$json = @{
  contributionIds = @(
      "ms.vss-build-web.checks-panel-data-provider"
  );
  dataProviderContext = @{
      properties = @{
          buildId = "${env:BUILD_BUILDID}";
          stageIds = "${env:SYSTEM_STAGEID}";
          checkListItemType = 3;
          sourcePage = @{
              url = "${env:SYSTEM_TEAMFOUNDATIONSERVERURI}${env:SYSTEM_TEAMPROJECT}/_build/results?buildId=${env:BUILD_BUILDID}";
              routeId = "ms.vss-build-web.ci-results-hub-route";
              routeValues = @{
                  project = "${env:SYSTEM_TEAMPROJECT}";
                  viewname = "build-results";
                  controller = "ContributedPage";
                  action = "Execute";
                  serviceHost = "${env:SYSTEM_COLLECTIONID}"
              }
          }
      }
  }
} | ConvertTo-Json -Depth 99

##########################################################
## Check to see if this was a rejected request
##########################################################
$release = api_post -url $response_url -token $env:SYSTEM_ACCESSTOKEN -body $json 

$approval_data = $release.dataProviders.'ms.vss-build-web.checks-panel-data-provider'.manualValidations.steps

if ($approval_data.status -ne 8) {
  Write-Host "Failed"
  Write-Host "##vso[task.setvariable variable=approved]Failed"
} else {
  Write-Host "Rejected: $($approval_data.comment)"
  Write-Host "##vso[task.setvariable variable=approved]Rejected"
  Write-Host "##vso[task.setvariable variable=comments]$($approval_data.comment)"
}