## `tfh workspace list`

List Terraform Enterprise workspaces for an organization

### Synopsis

    tfh workspace list [OPTIONS]

### Description

List Terraform Enterprise workspaces for an organization. An organization must be specified with the -name argument, the -tfe-org argument, or the TFE_ORG environment variable. Specifying a workspace is optional. If a workspace is specified with the -name argument, the -tfe-workspace argument, or the TFE_WORKSPACE environment variable it will be preceded by an asterisk.
