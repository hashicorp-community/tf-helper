## `tfh ssh delete`

Delete a Terraform Enterprise workspace

### Synopsis

    tfh ssh delete [OPTIONS]

### Description

SSH keys are defined at the organization level. An organization must be specified with the -name argument, the -tfe-org argument, or the TFE_ORG environment variable. A workspace does not need to be specified.

### Options

* `-ssh-name NAME`

The name of the SSH key to show.

* `-ssh-id ID`

The ID of the SSH key to show.

