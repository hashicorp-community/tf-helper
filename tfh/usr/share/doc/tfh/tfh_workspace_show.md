## `tfh workspace show, get`

Show Terraform Enterprise workspace details

### Synopsis

    tfh workspace show [WORKSPACE] [OPTIONS]

### Description

Show Terraform Enterprise workspace details.

### REST endpoint

    GET https://{HOSTNAME}/api/v2/organizations/{ORG}/workspaces/{WORKSPACE}

### Positional parameters

* `WORKSPACE`

The workspace to show can be given either using `-name` (and also `-prefix`), or given as a positional parameter.

### Documentation

https://www.terraform.io/docs/cloud/api/workspaces.html#show-workspace
