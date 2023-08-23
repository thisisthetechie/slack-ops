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
$messages_url = "https://slack.com/api/chat.postMessage"

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
$message = @(
  @{
    text = "Received Request"
    channel = $env:USER_ID
    blocks = @(
      @{
        type = "header"
        text = @{
          type = "plain_text"
          text = "New Request"
        }
      },
      @{
        type = "section"
        text = @{
          type = "mrkdwn"
          text = "Your request has been received!"
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
        type = "context"
        elements = @(
          @{
            type = "mrkdwn"
            text = "*Progress Flags:*"
          }
        )
      },
      @{
        type = "divider"
      },
      @{
        type = "context"
        elements = @(
          @{
            type = "mrkdwn"
            text = ":${env:ICON_APPROVED}: Approved"
          },
          @{
            type = "mrkdwn"
            text = ":${env:ICON_REJECTED}: Rejected"
          },
          @{
            type = "mrkdwn"
            text = ":${env:ICON_PROCESSING}: Processing"
          },
          @{
            type = "mrkdwn"
            text = ":${env:ICON_COMPLETE}: Completed"
          },
          @{
            type = "mrkdwn"
            text = ":${env:ICON_FAILED}: Failed"
          }
        )
      }
    )
  }
) | ConvertTo-Json -Depth 99

##########################################################
## Send Slack Message to User and get DM & Thread info
##########################################################
$slack_send = api_post -url $messages_url -token $slack_bot_token -body $message
$user_dm = $slack_send.channel
$user_thread = $slack_send.ts

Write-Host "Slack Message Sent"
Write-Host "User DM: $user_dm"
Write-Host "User Thread: $user_thread"

Write-Host "##vso[task.setvariable variable=user_dm;isoutput=true]$user_dm"
Write-Host "##vso[task.setvariable variable=user_thread;isoutput=true]$user_thread"
