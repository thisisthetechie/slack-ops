###########################################################
### Pipeline Approve/Reject
# The Pipeline will generate a Slack Message with 2 buttons:
# - Approve
# - Reject
#
# The following handles the responses to those button presses
###########################################################
import requests, json
from variables import *
from functions import *


###########################################################
## Simple function to call the DevOps API and get the latest 
## manual intervention for the release
###########################################################
def get_intervention_id(build_id, stage_id):
    req = requests.post(
        url     = VALIDATION_URL.format(ORGANIZATION, PROJECT),
        headers = AZDO_HEADER,
        data    = json.dumps(dict(
            contributionIds = ["ms.vss-build-web.checks-panel-data-provider"],
            dataProviderContext = dict(
                properties = dict(
                    buildId = build_id,
                    stageIds = stage_id,
                    checkListItemType = 3,
                    sourcePage = dict(
                        url = "https://dev.azure.com/{}/{}/_build/results?buildId={}&view=logs".format(ORGANIZATION, PROJECT, build_id),
                        routeId = "ms.vss-build-web.ci-results-hub-route",
                        routeValues = dict(
                            project = PROJECT,
                            viewname = "build-results",
                            controller = "ContributedPage",
                            action = "Execute",
                            serviceHost = ORGANIZATION_ID
                        ),
                    ),
                ),
            ),
        )),
    )

    return(json.loads(req.content)["dataProviders"]["ms.vss-build-web.checks-panel-data-provider"][0]["manualValidations"][0]["id"])

@app.action("reject")
## When the "Reject" button is pressed
def reject(ack, body, client, logger):
    ack()

    ## Open a modal view to capture a reason for the rejection
    ## This then passes on to the following @app.view
    forwarding_data = "{}_{}_{}".format(
        body["actions"][0]["value"], 
        body["channel"]["id"],
        body["message"]["ts"]
    )
    print(forwarding_data)
    client.views_open(
        trigger_id = body["trigger_id"],
        view_id = "home",
        view = View(
            type = "modal",
            private_metadata = forwarding_data,
            callback_id = "reject",
            title = PlainTextObject(text="Rejection Reason"),
            submit = PlainTextObject(text="Submit"),
            close = PlainTextObject(text="Cancel"),
            blocks = [
                InputBlock(
                    block_id="reject_reason",
                    element=PlainTextInputElement(
                        action_id="reject_reason",
                    ),
                    label=PlainTextObject(text="Reason for rejection"),
                ),
            ],
        ),
    )

@app.view("reject")
## Use the response from the rejection modal view and submit the rejection to Azure DevOps
def handle_reject(ack, body, respond, logger):

    user = body["user"]["id"]
    action_value = json.loads(body["view"]["private_metadata"].split('_')[0])
    ops_channel = body["view"]["private_metadata"].split('_')[1]
    ops_thread = body["view"]["private_metadata"].split('_')[2]
    intervention_id = get_intervention_id(action_value["buildId"],action_value["stageId"])
    reject_reason = body["view"]["state"]["values"]["reject_reason"]["reject_reason"]["value"]
    
    # Send the rejection to the Azure Pipeline
    req=requests.patch(
        url=APPROVAL_URL.format(
            organization = ORGANIZATION, 
            project      = PROJECT,
        ),
        data = json.dumps(
            [
                dict(
                    approvalId = intervention_id,
                    status = 8,
                    comment = reject_reason
                )
            ]
        ),
        headers=AZDO_HEADER,
    )
    print(req.text)
    if req.status_code == 200:
        # Add a comment in the thread to say who rejected it and why
        message(
            text="Rejected by <@{user}>.\n*Reason:* {reason}".format(
                user = user, 
                reason = reject_reason
            ), 
            thread = ops_thread,
            channel = ops_channel
        )
    ack()


@app.action("approve")
## When the "Approve" button has been pressed
def approve(ack, body, client, logger):
    user = body["user"]["id"]
    action_value = json.loads(body["actions"][0]["value"])
    intervention_id = get_intervention_id(action_value["buildId"],action_value["stageId"])

    # Send the approval to the Azure Pipeline
    req = requests.patch(
        url = APPROVAL_URL.format(
            organization = ORGANIZATION, 
            project      = PROJECT,
        ),
        data = json.dumps(
            [
                dict(
                    approvalId = intervention_id,
                    status = 4,
                    comment = "Approved via Slack"
                )
            ]
        ),
        headers = AZDO_HEADER,
    )
    print(req.text)
    if req.status_code == 200:
        
        # Add a comment in the thread to say who rejected it and why
        message(
            text="Approved by <@{user}>.".format(
                user = user
            ), 
            thread = body["message"]["ts"],
            channel = body["channel"]["id"]
        )
    ack()

## The "Visit Release" button was clicked, just acknowledge it
@app.action("visit_release")
def visit_button_clicked(ack, body, logger):
    ack()