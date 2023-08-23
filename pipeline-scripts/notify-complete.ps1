param(
  [string]$output,
  [string]$slack_bot_token
)

##########################################################
## Set URLs
##########################################################
$reaction_url = "https://slack.com/api/reactions.add"
$messages_url = "https://slack.com/api/chat.postMessage"

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
$message = @(
  @{
    type = "section"
    text = @{
      type = "mrkdwn"
      text = $output.replace("|", "`n")
    }
  }
)

##########################################################
## Set Payload Variables
##########################################################
$channel = $env:USER_DM
$thread  = $env:USER_THREAD

##########################################################
## Set Response Payload
##########################################################
$notification_payload = @{
  channel = $channel
  name = $env:ICON_COMPLETE
  timestamp = $thread
  token = $env:SLACK_BOT_TOKEN
} | ConvertTo-Json -Depth 99

##########################################################
## Set Message Payload
#########################################################
$message_payload = @{
  channel = $channel
  thread_ts = $thread
  blocks = $message
} | ConvertTo-Json -Depth 99

##########################################################
## Send Icon Notification
##########################################################
Write-Host "Sending Completed Reaction"
$notification = api_post -url $reaction_url -token $slack_bot_token -body $notification_payload
Write-Information $notification

##########################################################
## Send Message
##########################################################
Write-Host "Sending Message"
$message = api_post -url $messages_url -token $slack_bot_token -body $message_payload 
Write-Host $message