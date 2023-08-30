param(
  [string]$icon,
  [string]$slack_bot_token
)
##########################################################
## Set URL
##########################################################
$reaction_url = "https://slack.com/api/reactions.add"

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
  name = $icon
  timestamp = $env:USER_THREAD
  token = $env:SLACK_BOT_TOKEN
 } | ConvertTo-Json -Depth 99

##########################################################
## Send Icon Notification
##########################################################
$notification = api_post -url $reaction_url -token $slack_bot_token -body $notification_payload
Write-Host $notification