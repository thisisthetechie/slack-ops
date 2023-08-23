param(
  [string]$slack_bot_token
)

##########################################################
## Convert Pipeline Variables
##########################################################
$request_variables = $env:REQUEST_PARAMETERS | ConvertFrom-Json -Depth 99 -AsHashtable

##########################################################
## Set URLs
##########################################################
$slack_url   = "https://slack.com/api/chat.postMessage"

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
  if (($request.ok) -or ($request.id -gt 1)) {
    return $request
  } else {
    Write-Host $request
    Throw
  }
}

##########################################################
## Message object to send to Slack User (converted to JSON)
##########################################################
$request_vars = ""
foreach( $variable in $request_variables.Keys) {
  $TextInfo = (Get-Culture).TextInfo
  $name = $TextInfo.ToTitleCase($($variable).replace("_", " ").ToLower())
  $request_vars +=  "*$($name):* $($request_variables[$variable])`n"
}
$request_vars
$meta = @{
  buildId = ${env:BUILD_BUILDID};
  stageId = ${env:SYSTEM_STAGEID}
} | ConvertTo-Json
$message = @(
  @{
    text = "Received Request"
    channel = $env:CHANNEL
    blocks = @(
      @{
        type = "section"
        text = @{
          type = "mrkdwn"
          text = "New request received from *${env:USER_NAME}*"
        }
      },
      @{
        type = "section"
        text = @{
          type = "mrkdwn"
          text = "*Request Type:* ${env:REQUEST_TITLE}`n$($request_vars)"
        }
      },
      @{
        type = "actions"
        elements = @(
          @{
            type = "button"
            text = @{
              type = "plain_text"
              text = "Approve"            
            }
            style = "primary"
            value = $meta
            action_id = "approve"
          },
          @{
            type = "button"
            text = @{
              type = "plain_text"
              text = "Reject"            
            }
            style = "danger"
            value = $meta
            action_id = "reject"
          }
        )
      }
    )
  }
) | ConvertTo-Json -Depth 99


##########################################################
## Send Slack Message to Ops and get DM & Thread info
##########################################################
$message
$slack_send = api_post -url $slack_url -token $slack_bot_token -body $message
$ops_dm = $slack_send.channel
$ops_thread = $slack_send.ts

Write-Host "Slack Message Sent"
Write-Host "Ops DM: $ops_dm"
Write-Host "Ops Thread: $ops_thread"

Write-Host "##vso[task.setvariable variable=ops_dm;isoutput=true]$ops_dm"
Write-Host "##vso[task.setvariable variable=ops_thread;isoutput=true]$ops_thread"
