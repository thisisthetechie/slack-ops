"""Request Type Definitions."""
from slack_sdk.models.blocks import *

###########################################################
## Request Types
###########################################################
# ToDo: Get this from the actual collection values
GROUPS = [
    "Permission",
    "Resource",
    "Key Vault",
    "Other",
]

###########################################################
## Block Types
###########################################################
BLK_PROJECT_NAME = InputBlock(
    block_id = "project_name",
    label = TextObject(type="plain_text", text="Project Name"),
    element = PlainTextInputElement(action_id="project_name", placeholder="my-project")
)

BLK_PROJECT_SHORT_NAME = Block(
    block_id = "project_short_name",
    label = TextObject(type="plain_text", text="Project Short Name"),
    element = PlainTextInputElement(action_id="project_short_name", placeholder="acmelookup", max_length=14)
)

BLK_PROJECT_OWNER = InputBlock(
    block_id = "product_owner",
    label = TextObject(type="plain_text", text="Product Owner"),
    element = PlainTextInputElement(action_id="product_owner", placeholder="Gwen Stacy")
)

BLK_PROJECT_TEAM = InputBlock(
    block_id = "team_name",
    label = TextObject(type="plain_text", text="Team Name"),
    element = PlainTextInputElement(action_id="team_name", placeholder="Infrastructure")
)

BLK_COST_CODE = InputBlock(
    block_id = "cost_code",
    label = TextObject(type="plain_text", text="Cost Code"),
    element = PlainTextInputElement(action_id="cost_code", placeholder="P012345")
)

BLK_LOCATIONS = InputBlock(
    block_id = "locations",
    label = "Locations",
    element = StaticSelectElement(
       action_id = "locations",
       placeholder = "Select a Location",
       options = [
          Option(label = "UKSouth", value = "uksouth"),
          Option(label = "UKwest",  value = "ukwest"),
          Option(label = "All",     value = "uksouth,ukwest")
       ]
    )
)

BLK_PERMISSION_LEVEL = InputBlock(
   block_id = "permission_level",
   label = "Permission Level",
   element = PlainTextInputElement(action_id="permission_level", placeholder="Reader")
)

BLK_RESOURCE_GROUP = InputBlock(
   block_id = "resource_group",
   label = "Resource Group",
   element = PlainTextInputElement(action_id="resource_group", placeholder="acme-resource-group")
)

BLK_RESOURCE_LIST = InputBlock(
   block_id = "resource_list",
   label = "List of Resources",
   element = PlainTextInputElement(action_id="resource_list", placeholder="Comma separated list of resources")
)

BLK_SERVICE_CONNECTION_NAME = InputBlock(
   block_id = "service_connection_name",
   label = "Service Connection",
   element = PlainTextInputElement(action_id="service_connection_name", placeholder="acme-service-connection")
)

BLK_EMAIL_ADDRESS = InputBlock(
   block_id = "email",
   label = "Email Address",
   element = PlainTextInputElement(action_id="email", placeholder="gwen.stacy@mycorp.net")
)

BLK_KEY_VAULT = InputBlock(
   block_id = "key_vault",
   label = "Key Vault",
   element = PlainTextInputElement(action_id="key_vault", placeholder="acmekvdevuks")
)

###################################################################
### Subscriptions Action Block (will force update with new fields)
###################################################################
BLK_SUBSCRIPTION = [
    SectionBlock(
        text = dict(
            type = "mrkdwn",
            text = "*Subscription*"
        )
    ),
    ActionsBlock(
        block_id = "subscription",
        elements = dict(
            SelectElement(
                action_id = "subscription",
                options = [
                Option(label = "Development", value = "development"),
                Option(lable = "Integration", value = "integration"),
                Option(lable = "Staging",     value = "staging"),
                Option(lable = "Production",  value = "production")
                ],
                placeholder = "Select a Subscription"
            )
        )
    ),
    ContextBlock(
        elements = dict(
            TextObject(
                type = "mrkdwn",
                text = "_Note: Additional fields will be enabled depending on selection_"
            )
        )
    )
]

###################################################################
### Additional blocks to add if Production Environment is selected
###################################################################
BLK_PRODUCTION = [
    InputBlock(
        block_id="change_request",
        label=TextObject(type="plain_text", text="Change or Jira Number"),
        element=(PlainTextInputElement(action_id="change_request", placeholder="CHG0123456"))
    ),
    InputBlock(
        block_id="request_reason",
        label=TextObject(type="plain_text", text="Reason for the request"),
        element=(PlainTextInputElement(action_id="change_request"))
    )
]

###################################################################
### Service Connection Action Block (will force update with new fields)
###################################################################
BLK_SERVICE_CONNECTION = [
    ActionsBlock(
        block_id = "create_service_connection",
        elements = dict(
            CheckboxesElement(
               action_id = "create_service_connection",
               options = [
                  Option(
                     label = "Create Service Connection",
                     value = "create_service_connection"
                  )
               ]
            )
        )
    )
]

###################################################################
### Additional blocks to add if Service Connection is required
###################################################################
BLK_AZURE_PROJECT_NAME = [
   InputBlock(
        block_id="azure_project_name",
        label=TextObject(type="plain_text", text="Azure DevOps Project Name"),
        element=(PlainTextInputElement(action_id="azure_project_name", placeholder="acme-lookup"))
    )
]

###################################################################
### Create Requests Object
###################################################################
OPS_REQUESTS = dict(

    # Hello World Test Request
    req_hello_world = dict(
        group = "Resource",
        title_popup = "Hello World!",
        title_home = ":azdo: Hello World!",
        devops_pipeline_id = 0,
        command = "hello",
        approval_needed = "false",
        enabled = "false",
        blocks = [
            InputBlock(
                block_id = "hello_world",
                label = TextObject(type="plain_text", text="Enter Text"),
                element = PlainTextInputElement(action_id="hello_world")
            )
        ]
    ),

    # Request new Azure DevOps Project
    req_azdo_project = dict(
        group = "Resource",
        title_popup = "New Azure DevOps Project",
        title_home = ":azdo: Request new Azure DevOps Project",
        devops_pipeline_id = 0,
        command = "project",
        approval_needed = "true",
        enabled = "true",
        blocks = [
            BLK_PROJECT_NAME,
            BLK_PROJECT_SHORT_NAME,
            BLK_PROJECT_OWNER,
            BLK_PROJECT_TEAM,
            BLK_COST_CODE
        ]
    ),

    # Request new Azure Resource Group
    req_resource_group = dict(
        group = "Resource",
        title_popup = "New Azure Resource Group",
        title_home = ":rg: Request new Azure Resource Group",
        devops_pipeline_id = 0,
        command = "resource group",
        approval_needed = "false",
        enabled = "true",
        blocks = [
            BLK_SUBSCRIPTION,
            BLK_PROJECT_NAME,
            BLK_PROJECT_SHORT_NAME,
            BLK_LOCATIONS,
            BLK_PROJECT_OWNER,
            BLK_PROJECT_TEAM,
            BLK_COST_CODE,
            BLK_SERVICE_CONNECTION
        ]
    ),
        
    # Request permissions for Service Connection
    req_resource_group = dict(
        group = "Permission",
        title_popup = "Service Connection Perms",
        title_home = ":perms: Request Permissions for a Service Connection",
        devops_pipeline_id = 0,
        command = "service permissions",
        approval_needed = "false",
        enabled = "true",
        blocks = [
            BLK_SUBSCRIPTION,
            BLK_PROJECT_NAME,
            BLK_PROJECT_SHORT_NAME,
            BLK_LOCATIONS,
            BLK_PROJECT_OWNER,
            BLK_PROJECT_TEAM,
            BLK_COST_CODE,
            BLK_SERVICE_CONNECTION_NAME,
            BLK_RESOURCE_LIST,
            BLK_PERMISSION_LEVEL
        ]
    ),

    # Request permissions for User
    req_resource_group = dict(
        group = "Permission",
        title_popup = "User Perms",
        title_home = ":perms: Request Permissions for a User",
        devops_pipeline_id = 0,
        command = "user permissions",
        approval_needed = "false",
        enabled = "true",
        blocks = [
            BLK_SUBSCRIPTION,
            BLK_EMAIL_ADDRESS,
            BLK_RESOURCE_GROUP,
            BLK_RESOURCE_LIST,
            BLK_PERMISSION_LEVEL
        ]
    ),

    # Restore a Key Vault from Deleted Vaults
    req_kv_restore = dict(
        group = "Key Vault",
        title_popup = "Restore Key Vault",
        title_home = ":kv: Request the _*Restoration*_ of a Deleted Azure Key Vault",
        devops_pipeline_id = 0,
        command = "keyvault restore",
        approval_needed = "false",
        enabled = "true",
        blocks = [
            BLK_SUBSCRIPTION,
            BLK_LOCATIONS,
            BLK_KEY_VAULT
        ]
    ),

    # Purge a Key Vault from Deleted Vaults
    req_kv_purge = dict(
        group = "Key Vault",
        title_popup = "Purge Key Vault",
        title_home = ":kv: Request the _*Purging*_ of a Deleted Azure Key Vault",
        devops_pipeline_id = 0,
        command = "keyvault purge",
        approval_needed = "false",
        enabled = "true",
        blocks = [
            BLK_SUBSCRIPTION,
            BLK_LOCATIONS,
            BLK_KEY_VAULT
        ]
    )
)


