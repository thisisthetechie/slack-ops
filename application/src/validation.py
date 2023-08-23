import re

VALIDATIONS = dict(
    email = dict(
        pattern = "^[a-z\.0-9]+@[a-z0-9-]+\.[com|net|co.uk|uk|net.uk|org.uk|org]$",
        error   = "Please provide a valid email address."
    ),
    resource_list = dict(
        pattern = "^(?!.*rg)(?:[a-z]+-[a-z-]+-([a-z-]+)-(dev|int|stag|prod)-(?:uk[s|w])[-a-z]+[,]*)+$",
        error   = "Resource names must follow the format: [org]-[shortname]-[restype]-[environment]-[location]."
    ),
    project_name = dict(
        pattern = "^[A-Za-z0-9-\s]+$",
        error   = "Project Name is the full title of the Project."
    ),
    azure_project_name = dict(
        pattern = "^[a-z-\.]+$",
        error   = "Please provide the Azure DevOps Project Name (e.g. example-acme-service)."
    ),
    project_short_name = dict(
        pattern = "^[a-z]{2,14}$",
        error   = "Project Short Name is used as a key for all resources, it must be less than 14 characters long and not contain any spaces or hyphens."
    ),
    cost_code = dict(
        pattern = "^P[0-9]{4}/[0-9]{2}$",
        error   = "Cost Codes must follow the format: P0000/00."
    ),
    product_owner = dict(
        pattern = "^[A-Za-z\s-]*$",
        error   = "Please provide a valid Product Owner's name."
    ),
    product_name = dict(
        pattern = "^[A-Za-z\s-]*$",
        error   = "Please provide a valid Product name."
    ),
    team_name = dict(
        pattern = "^[A-Za-z\s-]*$",
        error   = "Please provide a valid Team name."
    ),
    permission_level = dict(
        pattern = "^[A-Za-z\s-]*$",
        error   = "Please provide a single valid Permission Type (e.g. Reader or Contributor etc)."
    ),
    change_request = dict(
        pattern = "^(?:CHG(?:\d){7}|(?:[A-Za-z0-9]){3,10}-[0-9]{4,6})$",
        error   = "Please provide a valid Change Request or Jira Ticket Number."
    ),
    request_reason = dict(
        pattern = "^(?:\w+(?:[,.]*\s)){6,}\w+[.]*$",
        error   = "Please provide a valid reason for the request."
    )
)

def validate_input(input, value):
    ## Check for a valid email address
    result = dict(
        validated = True,
        error     = None
    )
    match = re.match(VALIDATIONS.get(input, dict(pattern = ".*", error = "Default"))["pattern"], value)
    if match is None:
        result["validated"] = False
        result["error"] = VALIDATIONS[input]["error"]
    else:
        if input == "resource_list" and (match.group(1) == "rg" and match.group(2) == "prod"):
            result["validated"] = False
            result["error"] = "You can only request access to individual resources in Production Resource Groups"
        if input == "permission_level" and match.string == "Owner":
            result["validated"] = False
            result["error"] = "You can not request Owner permissions for Azure Resources"
    
    return result