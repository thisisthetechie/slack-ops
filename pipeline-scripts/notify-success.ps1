param(
  [string]$slack_bot_token,
  [string]$comments
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
## Set Response Payload
##########################################################
$notification_payload = @{
    channel = $env:USER_DM
    name = $env:ICON_COMPLETE
    timestamp = $env:USER_THREAD
    token = $env:SLACK_BOT_TOKEN
 } | ConvertTo-Json -Depth 99

##########################################################
## Send Icon Notification
##########################################################
Write-Host "Sending Success Reaction to User"
$notification = api_post -url $reaction_url -token $slack_bot_token -body $notification_payload
Write-Information $notification

##########################################################
## Set Message Payload
##########################################################
$message_payload = @{
  channel = $env:USER_DM
  thread_ts = $env:USER_THREAD
  blocks = @(
    @{
      type = "section"
      text = @{
        type = "mrkdwn"
        text = "Your request has completed with the following comments:`n_${comments}_"
      }
    }
  )
} | ConvertTo-Json -Depth 99

##########################################################
## Send Message
##########################################################
Write-Host "Sending Success Message to User"
$message = api_post -url $messages_url -token $slack_bot_token -body $message_payload 
Write-Information $message