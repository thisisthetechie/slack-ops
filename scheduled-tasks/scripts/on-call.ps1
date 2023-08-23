##########################################################
### Set Internal Variables
##########################################################
Param(
  [string]$opsgenie_subscription_id,
  [string]$opsgenie_api_key,
  [string]$slack_bot_token
)

##########################################################
## Set URLs 
##########################################################
$messages_url = "https://slack.com/api/chat.postMessage"
$on_call_url  = "https://api.opsgenie.com/v2/schedules/${opsgenie_subscription_id}/on-calls?scheduleIdentifierType=id&date="

##########################################################
## Define Functions 
##########################################################
function api_post() {
  ## Generic POST or PUT Function
  Param (
    [string]$url,
    [string]$token,
    [string]$body,
    [string]$authType,
    [string]$method = "post"
  )
  $header = @{
    Authorization  = "${authType} ${token}" 
    "Content-Type" = "application/json"
  }
  $request = Invoke-RestMethod -Uri $url -Method $method -Headers $header -Body $body
  if ($request.ok) {
    Return $request.ok
  } else {
    Write-Host $request
    Write-Host $request.ok
    Throw $request
  }
}

function api_get() {
  ## Basic GET Function
  Param (
    [string]$url,
    [string]$token,
    [string]$authType
  )
  $header = @{
    Authorization  = "${authType} ${token}"
    "Content-Type" = "application/json"
  }

  $request = Invoke-RestMethod -Uri $url -Method get -Headers $header 
  if (($request.ok -eq "False") -or [string]::IsNullOrEmpty($request.data)) {
    Write-Host $request
    Throw
  } else {
    return $request
  }
}

#####################################################################
### Generate Message Object
#####################################################################
$message = @{
  channel = $env:CHANNEL
  blocks  = @(
    @{
      type = "header";
      text = @{
        type = "plain_text";
        text = "On-Call Schedule";
        emoji = $true
      }
    };
    @{
      type = "section";
      text = @{
        type = "plain_text";
        text = "Infrastructure Team on-call schedule over the next 2 weeks:";
        emoji = $true
      }
    };
    @{
      type = "section";
      fields = @(
        @{
          type = "mrkdwn";
          text = "*Date*";
        };
        @{
          type = "mrkdwn";
          text = "*Engineer*";
        };
      )
    };
    @{
      type = "section";
      fields = @()
    };
    @{
      type = "section";
      fields = @()
    };
    @{
      type = "section";
      fields = @()
    };
    @{
      type = "section";
      fields = @()
    };
    @{
      type = "section";
      text = @{
        type = "plain_text";
        text = "The Engineer on-call will be your initial contact should you require urgent assistance with regards to ongoing changes or serious incidents.";
        emoji = $true
      }
    };
    @{
      type = "divider";
    };
    @{
      type = "context";
      elements = @(
        @{
          type = "mrkdwn";
          text = "_Note: This list is automatically generated from the On-Call Schedule within the Alerting System used by Infrastructure and can be subject to change without notice._";
        }
      )
    };
  )
}

#####################################################################
### Compile Dates
#####################################################################
$startdate = $(Get-Date)
$block     = 2
 
Write-Host "Getting Schedule:"
foreach ($day in 0..13) {
    
  # Convert the date to International
  $datetime = "$(Get-Date $startdate -Format 'yyyy-MM-dd')T08:01:00z"
  $datetime
  $request  = api_get -url "${on_call_url}${datetime}" -authType GenieKey -token $opsgenie_api_key

  ## Get On-Call Engineer Details
  $oncallid = $request.data.onCallParticipants
  $oncallmatch = Select-String "([a-z]+)" -AllMatches -InputObject $oncallid.name
  $oncallperson = '{0} {1}' -f $oncallmatch.Matches.groups[1], $oncallmatch.Matches.groups[2]
  $oncallperson = (Get-Culture).TextInfo.ToTitleCase($oncallperson)
  $dayofweek = $startdate.DayOfWeek
  if ($dayofweek -in @("Monday","Saturday")) {
    $block ++
  }

  ## Add to Message Block
  $message.blocks[$block].fields += @{type="mrkdwn";text="$dayofweek $($startdate.ToShortDateString())"} 
  $message.blocks[$block].fields += @{type="mrkdwn";text="${oncallperson}"} 
  Write-Host "$($dayofweek.ToString().PadRight(10,[char]32)) $($startdate.ToShortDateString()) $oncallperson"
  $startdate = $startdate.AddDays(1)
}

#####################################################################
### Output Message
#####################################################################
api_post -url $messages_url -authType Bearer -token $slack_bot_token -body $( $message | ConvertTo-Json -Depth 99)