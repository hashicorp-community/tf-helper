## `tfh workspace list`

List Terraform Enterprise workspaces for an organization

### Synopsis

    tfh workspace list [OPTIONS]

### Description

List Terraform Enterprise workspaces for an organization. An organization must be specified with the `-org` argument, or the `TFH_org` environment variable. Specifying a workspace is optional. If a workspace is specified with the `-name` argument or the `TFH_name` environment variable it will be preceded by an asterisk.
