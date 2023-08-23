import re, requests, json
import logging
from variables import *
from functions import *
from datetime import date

###########################################################
### Handle the /request Command
# A user can type "/request" anywhere in Slack 
# The command is expecting a command keyword (such as project or resourcegroup),
# if the keyword is not submitted, the user will get a "usage" message.
# Otherwise, the relevant modal view is presented
###########################################################
@app.command("/request")
def handle_command(body, ack, respond, client, logger):
### Handle the /request [Request Type] shortcut

    ## Find the Ops Request ID to use
    req_id = None
    for req in OPS_REQUESTS.keys():
        if OPS_REQUESTS[req]["command"] == body["text"]:
            req_id = req

    if req_id == None:
        # No req_id was found
        ack(
            blocks=usage_output(body["text"]),
        )
    else:
        ack()
        ### Create the Modal (popup) view
        res = create_popup(
            client = client, 
            trigger_id = body["trigger_id"],
            view_id = "home",
            req_id = req_id,
            callback_id = "view-id"
        )
        logging.warning(res)
    
###########################################################
### Handle the /oncall Command
# A user can type "/oncall" anywhere in Slack to find out
# who is on call 
# Using "/oncall" with a date will respond with who will be
# on call on a specific date
###########################################################
@app.command("/oncall")
def handle_command(body, ack, respond, client, logger):
### Handle the /oncall [Date] shortcut

    on_call_date = ""
    date_output  = "today"

    # If a date is passed to the command, use that
    match = re.match("^(\d{1,2})\/(\d{1,2})\/(\d{2,4})$", body["text"])
    if not match is None:
        on_call_date = "&date={}-{}-{}T08:01:00z".format(match.group(3), match.group(2), match.group(1))

        # Create an alternative output to show the specified date was used
        date_output = "on {}".format(date(int(match.group(3)), int(match.group(2)), int(match.group(1))).strftime("%A %B %d %Y"))

    # Get the on call engineer from OpsGenie
    on_call_data = requests.get(OPSGENIE_URL + on_call_date, headers = OPSGENIE_HEADER )
    on_call_user = re.match("([a-z]+)\.([a-z]+).*", json.loads(on_call_data.text)["data"]["onCallParticipants"][0]["name"])

    # Make the name more readable
    engineer = "{} {}".format(on_call_user.group(1), on_call_user.group(2)).title()

    ack(
        # Send the output to the user
        "{} is on call {}".format(engineer, date_output)
    )

###########################################################
## Simple function to create a "Usage" message to a user
## if they just enter "/request" without a valid Request Type keyword
###########################################################
def usage_output(request: None):
    ## Generate the main intro for the usage information

    print(request)
    group_block = []

    group_block.append(
        HeaderBlock(
            text=COMMAND_TITLE
        )
    )

    if request != "":
    ## Unrecognised Value Provided
        message = ":confused: _*Invalid Request Type:* {request}_".format(
            request = request
        )
        group_block.append(
            SectionBlock(
                text = MarkdownTextObject(
                    text = message
                )
            )
        )

    else:
        group_block.append(
            SectionBlock(
                text = PlainTextObject(
                    text = COMMAND_INFO
                )
            )
        )

    group_block.append(
        SectionBlock(
            text = MarkdownTextObject(
                text = COMMAND_USAGE
            )
        )
    )

    ## Generate the commands and their titles to display to the user
    section_block = ""
    for group in GROUPS:
        for request_name in OPS_REQUESTS:
            if OPS_REQUESTS[request_name]["group"] == group and OPS_REQUESTS[request_name]["enabled"] == "true":
                section_block += "- `{}` - {}\n".format( 
                    OPS_REQUESTS[request_name]["command"], 
                    # Remove icons from titles
                    re.sub(r'(?is):.*:[\s]*', '', OPS_REQUESTS[request_name]["title_home"])
                )

    group_block.append(
        SectionBlock(
            text = MarkdownTextObject(
                text = section_block
            )
        )
    )            
    
    ## Return back to the calling function
    return(group_block)