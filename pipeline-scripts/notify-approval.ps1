param(
  [string]$slack_bot_token,
  [string]$approved,
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
## Identify which Icons to use
##########################################################
if ($approved -eq "true") {
  $icon = $env:ICON_APPROVED
} else {
  $icon = $env:ICON_REJECTED
}
Write-Information $icon

##########################################################
## Set Response Payload
##########################################################
$notification_payload = @{
    channel = $env:USER_DM
    name = $icon
    timestamp = $env:USER_THREAD
    token = $slack_bot_token
 } | ConvertTo-Json -Depth 99

##########################################################
## Send Icon Notification
##########################################################
Write-Host "Sending $icon Reaction to User"
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
        text = "Your request was rejected with the following comments:`n${comments}"
      }
    }
  )
} | ConvertTo-Json -Depth 99

##########################################################
## Send Message (if rejected)
##########################################################
if ($approved -ne "true") {
  Write-Host "Sending Rejection Message to User"
  $message = api_post -url $messages_url -token $slack_bot_token -body $message_payload 
  Write-Information $message
}

##########################################################
## Initialise Request Log
##########################################################
Write-Host "##vso[task.setvariable variable=output]*Request Log:*|"
