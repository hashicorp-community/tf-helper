## `tfh var new, create`

Create a new TFC/Eworkspace variable

### Synopsis

    tfh var new|create .data.attributes.key KEY [JSON_OPTIONS]

### REST endpoint

    POST https://{HOSTNAME}/api/v2/vars

### Description

Create a new Terraform Enterprise SSH key.  SSH keys are defined at the organization level. An organization must be specified with the -name argument, the -tfe-org argument, or the TFE_ORG environment variable. A workspace does not need to be specified.

### Options

* `.data.type TYPE`

Must be "vars". [default: `vars`]

* `.data.attributes.key KEY`

The name of the variable.

* `.data.attributes.value VALUE`

The value of the variable.

* `.data.attributes.description DESCRIPTION`

The description of the variable.

* `.data.attributes.category CATEGORY`

Whether this is a Terraform or environment variable. Valid values are "terraform" or "env". [default: `terraform`]

* `.data.attributes.hcl`

Whether to evaluate the value of the variable as a string of HCL code. Has no effect for environment variables.

* `.data.attributes.sensitive`

Whether the value is sensitive. If true then the variable is written once and not visible thereafter.

* `.data.relationships.workspace.data.type TYPE`

Must be "workspaces". [default: `workspaces`]

* `.data.relationships.workspace.data.id ID`

The ID of the workspace that owns the variable. Obtain workspace IDs from the workspace settings or the Show Workspace endpoint.

# Documentation

https://www.terraform.io/docs/cloud/api/variables.html#create-a-variable
