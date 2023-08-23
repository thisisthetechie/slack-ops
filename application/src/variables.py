"""Variables for SlackOps App."""
import json, os, re
#from slackops import devops_token

###################################################################
### Constants for the App as a whole
###################################################################
SLACK_BOT_TOKEN          = os.environ.get("SLACK_BOT_TOKEN")
SLACK_SIGNING_SECRET     = os.environ.get("SLACK_SIGNING_SECRET")
DEVOPS_TOKEN             = os.environ.get("DEVOPS_TOKEN")
APP_VERSION              = str(os.environ.get("APP_VERSION")).replace("v","")
OPSGENIE_API_KEY         = os.environ.get("OPSGENIE_API_KEY")
OPSGENIE_SUBSCRIPTION_ID = os.environ.get("OPSGENIE_SUBSCRIPTION_ID")
ENVIRONMENT              = "Development"
HOME_PAGE_TITLE          = ":robot-face: Developer Operations"
HOME_PAGE_DESCRIPTION    = """
Welcome to the DevOps Portal
From here, you can place requests for common tasks without having to create an individual Support Ticket.
"""
COMMAND_TITLE = "Make an Ops Request"  
COMMAND_INFO  = "Make a request to the DevOps Service."  
COMMAND_USAGE = """
*Usage:* `/request [Request Type]`

*Request Types:*
"""
GROUPS = [
    "Permission",
    "Resource",
    "Key Vault",
    "Other",
]
OPS_CHANNEL = "slack-ops"
ORGANIZATION = "my-org"
ORGANIZATION_ID = "afb040f9-649c-4c64-bd23-791f75b378c4"
PROJECT = "slack-ops"
PIPELINE_RUN_URL =  "https://dev.azure.com/{}/{}/_apis/pipelines/{}/runs?api-version=7.0"
VALIDATION_URL = "https://dev.azure.com/{}/_apis/Contribution/HierarchyQuery/project/{}?api-version=7.0-preview"
APPROVAL_URL = "https://dev.azure.com/{organization}/{project}/_apis/pipelines/approvals?api-version=7.0-preview"
INTERVENTION_DATA = {
    "status": "rejected",
    "comment": ""
}
AZDO_HEADER = {
    "Content-Type": "application/json", 
    "Authorization": "Basic {token}".format(
        token = DEVOPS_TOKEN
    )
}
OPSGENIE_HEADER = {
  "Authorization": "GenieKey {token}".format(
        token = OPSGENIE_API_KEY
    )
}
OPSGENIE_URL = "https://api.opsgenie.com/v2/schedules/%s/on-calls?scheduleIdentifierType=id" % OPSGENIE_SUBSCRIPTION_ID

###################################################################
### Collection of blocks for each Request Type - Read from a JSON File
###################################################################
with open('request_types.json') as request_types_file:
  OPS_REQUESTS = json.load(request_types_file)

###################################################################
### Additional blocks to add if Production Environment is selected
###################################################################
PRODUCTION_BLOCKS = """
[
    {
        "type": "input",
        "block_id": "change_request",
        "element": {
            "type": "plain_text_input",
            "action_id": "change_request",
            "placeholder": "CHG0123456"
        },
        "label": {
            "type": "plain_text",
            "text": "Change or Jira Number"
        }
    },
    {
        "type": "input",
        "block_id": "request_reason",
        "element": {
            "type": "plain_text_input",
            "action_id": "request_reason",
            "min_length": 20
        },
        "label": {
            "type": "plain_text",
            "text": "Reason for the request"
        }
    }
]
"""

###################################################################
### Additional blocks to add if Service Connection is required
###################################################################
AZURE_PROJECT_BLOCKS = """
[    
    {
        "type": "input",
        "block_id": "azure_project_name",
        "element": {
        "type": "plain_text_input",
        "action_id": "azure_project_name",
        "placeholder": "acme-lookup"
        },
        "label": {
        "type": "plain_text",
        "text": "Azure DevOps Project Name"
        }
    }
]
"""

###################################################################
### Calculate the running environment
###################################################################
if os.environ.get("CONTAINER_APP_NAME"):
    match = re.match("slackops-app-([a-z]+)-uk[s|w]", os.environ.get("CONTAINER_APP_NAME"))
    if match.group(1) == "prod":
        ENVIRONMENT = "Production"
