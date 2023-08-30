import json
import logging
from variables import *
from validation import *
from functions import *
from approval import *
from commands import *
from request_types import OPS_REQUESTS, GROUPS
from slack_sdk.models.views import View
from slack_sdk.models.blocks import *

logging.basicConfig(level=logging.WARNING)

###########################################################
## Middleware Declaration - it's there because it's there
###########################################################
@app.middleware  # or app.use(log_request)
def log_request(logger, body, next):
    logging.debug(body)
    return next()

###########################################################
### Home Screen for the App
# This is the "App Home" screen and presents the user with a list of all
# request types that are currently supported with a button to launch the 
# required request
###########################################################
@app.event("app_home_opened")
def update_home_tab(client, event, logger):

    try:
        ### Set the Default Group Block for the Home Page Display
        group_block = [
            HeaderBlock(
                text=HOME_PAGE_TITLE
            )
        ]
        group_block.append(SectionBlock(
                text=PlainTextObject(text=HOME_PAGE_DESCRIPTION)
            )
        )
        group_block.append(DividerBlock())
        print(group_block)
        ### Add in the Grouped Items
        for group in GROUPS:
            tmp_group_block = [ HeaderBlock(text=group + " Requests:") ]
            for request_name in OPS_REQUESTS:
                if OPS_REQUESTS[request_name]["group"] == group and OPS_REQUESTS[request_name]["enabled"] == "true":
                    tmp_group_block.append(
                        SectionBlock(
                            text=MarkdownTextObject(text=OPS_REQUESTS[request_name]["title_home"]),
                            accessory=ButtonElement(text=PlainTextObject(text="Request"), action_id="req_start", value=request_name)               
                        )
                    )
            if len(tmp_group_block) > 1:
                group_block.extend(tmp_group_block)

        # Add the App Version number
        group_block.append(DividerBlock())
        group_block.append(
            ContextBlock(
                elements = [ 
                    MarkdownTextObject(
                        text="_v{app_version}_".format(
                            app_version = APP_VERSION
                        )
                    ) 
                ]
            )
        )

        print(group_block)

        ### Create the Home View
        client.views_publish(
            user_id=event["user"],
            view=View(
                type="home",
                callback_id="view-id",
                title=PlainTextObject(text=HOME_PAGE_TITLE),
                blocks=group_block,
            )
        )
    except Exception as e:
        logger.error(f"Error publishing home tab: {e}")


###########################################################
### Modal View Popup
# This is the main "view" that is presented to the user to complete
# It can be called either by the Home Page buttons or by a /request [Request Type] command in slack
###########################################################
@app.action("req_start")
## Display the popup form, the contents of which are defined by the calling process
def display_request_form(ack, body, client, logger):
    ack()

    ### Create the Modal (popup) view
    create_popup(
        client = client, 
        trigger_id = body["trigger_id"],
        view_id = "home",
        req_id = body["actions"][0]["value"],
        callback_id = "view-id"
    )

###########################################################
### Validate and Submit Request
###########################################################
@app.view("view-id")
## Handle the response from the relevant modal view form completed by the user
def view_submission(ack, body, logger):

    user = body["user"]["id"]
    user_profile = app.client.users_profile_get(user=user)
    request_type = body["view"]["private_metadata"]

    ### Create a collection of variables
    request_object=dict(
        request_type = dict(value = request_type),
        user_id = dict(value = user),
        user_name = dict(value = user_profile.data["profile"]["real_name"]),
        request_title = dict(value = body["view"]["title"]["text"]),
        approval_needed = dict(value = OPS_REQUESTS[request_type]["approval_needed"])
    )
    request_parameters=dict()
    errors = {}
    value = None
    print("NEW REQUEST:\nUser: {}\nRequest Type: {}".format(request_object["user_name"]["value"], request_object["request_title"]["value"]))
    for key in body["view"]["state"]["values"].keys():
        for input_name in body["view"]["state"]["values"][key].keys():

            ## Send the Input Name and Value and validate it matches the organizational requirements for naming etc
            if body["view"]["state"]["values"][key][input_name]["type"] not in ["static_select", "checkboxes"]:
                input_value = body["view"]["state"]["values"][key][input_name]["value"]
                print("Validating text input of {}: {}".format(input_name, input_value))
                value = validate_input(input_name, input_value)
                if value["validated"] == False:
                    print("Validation failed:", value["error"])
                    errors[input_name] = value["error"]
                else:
                    value = input_value

            ## Handle non-text values
            elif body["view"]["state"]["values"][key][input_name]["type"] == "checkboxes":
                if len(body["view"]["state"]["values"][key][key]["selected_options"]) == 1:
                    value = True
                else:
                    value = False

            else: 
                value = body["view"]["state"]["values"][key][key]["selected_option"]["value"]

            ## Add some protection for Production Environments
            if key == "subscription" and value == "production":
                request_object["approval_needed"] = dict(value = "true")

            if key == "subscription" and ENVIRONMENT == "Development":
                value = "development"
                

            ## Add the value to the variables collection
            request_parameters.update({key:value})

    request_object.update(request_parameters = dict(value = json.dumps(request_parameters)))
    print("REQUEST OBJECT:\n",request_object)

    if len(errors) > 0:
        ## If there were errors, notify the user
        ack (
            response_action = "errors",
            errors = errors
        )
    else:       
        response = submit_request(request_object, request_type)
        if response.status_code != 200:
            print("Failed:", response.status_code)
            print(response.text)
        else:
            ack()

###########################################################
### Start the app
###########################################################
if __name__ == "__main__":
    app.start(port=int(PORT))
