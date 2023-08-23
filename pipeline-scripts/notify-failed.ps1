param(
  # Pass in either "ops" or "user"
  [string]$target,
  [string]$operation,
  [string]$slack_bot_token
)

##########################################################
## Set URLs
##########################################################
$reaction_url = "https://slack.com/api/reactions.add"
$messages_url = "https://slack.com/api/chat.postMessage"

##########################################################
## Set Ops Channel
##########################################################
if ( $env:APPROVAL_NEEDED -eq "true" ) {
  $ops_channel = $env:OPS_DM
} else {
  $ops_channel = $env:CHANNEL
}

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
  if (($request.ok) -or ($request.id -gt 1)) {
    return $request
  } else {
    Write-Host $request
    Throw
  }
}

##########################################################
## Set User Message Blocks
##########################################################
$user_message = @(
  @{
    type = "section"
    text = @{
      type = "mrkdwn"
      text = "Your request failed to complete, the Ops team have been notified"
    }
  }
)

##########################################################
## Set Ops Message Blocks
##########################################################
$ops_message = @(
  @{
    type = "section"
    text = @{
      type = "mrkdwn"
      text = "${operation} failed to complete!`nVisit the request to view the logs"
    }
  },
  @{
    type = "actions"
    elements = @(
      @{
        type = "button"
        text = @{
          type = "plain_text"
          text = "Visit Request"
        }
        value = "visit_release"
        action_id = "visit_release"
        url = "${env:SYSTEM_TEAMFOUNDATIONSERVERURI}${env:SYSTEM_TEAMPROJECT}/_build/results?buildId=${env:BUILD_BUILDID}&view=results"
      }
    )
  }
)

##########################################################
## Set Payload Variables
##########################################################
$payload_options = @{
  ops = @{
    channel = $ops_channel
    thread  = $env:OPS_THREAD
    message = $ops_message
  }
  user = @{
    channel = $env:USER_DM
    thread  = $env:USER_THREAD
    message = $user_message
  }
}

##########################################################
## Set Response Payload
##########################################################
$notification_payload = @{
    channel = $payload_options.$target.channel
    name = $env:ICON_FAILED
    timestamp = $payload_options.$target.thread
    token = $env:SLACK_BOT_TOKEN
} | ConvertTo-Json -Depth 99

##########################################################
## Set Message Payload
#########################################################
 $message_payload = @{
  channel = $payload_options.$target.channel
  thread_ts = $payload_options.$target.thread
  blocks = $payload_options.$target.message
 }| ConvertTo-Json -Depth 99

##########################################################
## Send Icon Notification
##########################################################
if ( $target -eq "user" ) {
  Write-Host "Sending $icon Reaction"
  $notification = api_post -url $reaction_url -token $slack_bot_token -body $notification_payload
  Write-Information $notification
}

##########################################################
## Send Message
##########################################################
Write-Host "Sending Message"
$message = api_post -url $messages_url -token $slack_bot_token -body $message_payload 
Write-Host $message