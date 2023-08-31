import requests
from variables import *
from request_types import OPS_REQUESTS, BLK_PRODUCTION, BLK_AZURE_PROJECT_NAME
from slack_bolt import App, Say
from slack_sdk.models.views import View
from slack_sdk.models.blocks import *

app = App(
    token          = SLACK_BOT_TOKEN,
    signing_secret = SLACK_SIGNING_SECRET
)

###########################################################
## Simple function to send a message
###########################################################
def message(text, thread = None, channel = None):
    say = Say(
        client = app.client,
        channel = OPS_CHANNEL,
    )

    say(
        text=text,
        thread_ts=thread,
        mrkdwn = True,
        channel = channel
    )

###########################################################
## Simple function to submit an API request to the relevant Release Pipeline,
## triggering a release to be created with the captured variables
###########################################################
def submit_request(request_object, request_type):    
    headers = AZDO_HEADER
    devops_pipeline_id = OPS_REQUESTS[request_type]["devops_pipeline_id"]
    payload = dict(
        variables = request_object
    )
    response = requests.post(PIPELINE_RUN_URL.format(ORGANIZATION, PROJECT, devops_pipeline_id), json = payload, headers = headers )
    print(response.text)
    return(response)

###########################################################
## Simple function to simplify the creation of the Request
## popup - rather than having the same code in multiple places
###########################################################
def create_popup(client, trigger_id, view_id, req_id, callback_id):
    ### Get the values for the selected request type
    req_title  = OPS_REQUESTS[req_id]['title_popup']
    req_blocks = OPS_REQUESTS[req_id]['blocks']

    return(client.views_open(
            trigger_id = trigger_id,
            view_id = view_id,
            view = View(
                type = "modal",
                private_metadata = req_id,
                callback_id = callback_id,
                title = PlainTextObject(text=req_title),
                submit = PlainTextObject(text="Submit"),
                close = PlainTextObject(text="Cancel"),
                blocks = req_blocks,
            ),
        )
    )

###########################################################
## Simple function to simplify the updating of the Request
## popup - rather than having the same code in multiple places
###########################################################
def update_popup(client, body, additional_blocks, add_blocks, callback_id = "view-id"):
    ### Get the values for the selected request type
    req_id = body["view"]["private_metadata"]
    view_id = body["view"]["id"]
    body_blocks = body['view']['blocks']
    req_title  = OPS_REQUESTS[req_id]['title_popup']

    #additional_blocks = json.loads(additional_blocks)
    block_exists = False
    for extra_block in additional_blocks:
        for block in body_blocks:
            if extra_block['block_id'] == block['block_id']:
                    block_exists = True
                    if not add_blocks:
                        body_blocks.remove(block)

    if add_blocks and not block_exists:
        body_blocks.extend(additional_blocks)

    return(client.views_update(
            view_id = view_id,
            view = View(
                type = "modal",
                private_metadata = req_id,
                callback_id = callback_id,
                title = PlainTextObject(text=req_title),
                submit = PlainTextObject(text="Submit"),
                close = PlainTextObject(text="Cancel"),
                blocks = body_blocks,
            ),
        )
    )

###########################################################
### Modal Action - add/remove extra Input fields if Production
###########################################################
@app.action("subscription")
def update_modal(ack, body, client, logger):
    # Identify if using a protected environment
    if body['actions'][0]['selected_option']['value'] in ["production"]:
        is_prod = True
    else:
        is_prod = False

    update_popup(
        client = client, 
        body = body,
        additional_blocks = BLK_PRODUCTION,
        add_blocks = is_prod
    )
    ack()

###########################################################
### Modal Action - add/remove extra Input fields if Service Connection required
###########################################################
@app.action("create_service_connection")
def update_modal(ack, body, client, logger):
    if len(body['actions'][0]['selected_options']) == 1:
        add_blocks = True
    else:
        add_blocks = False

    update_popup(
        client = client, 
        body = body,
        additional_blocks = BLK_AZURE_PROJECT_NAME,
        add_blocks = add_blocks
    )
    ack()