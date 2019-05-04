## `tfh ssh show`

Show Terraform Enterprise workspace details

### Synopsis

    tfh ssh show [OPTIONS]

### Description

Show Terraform Enterprise SSH key details.  SSH keys are defined at the organization level. An organization must be specified with the -name argument, the -tfe-org argument, or the TFE_ORG environment variable. A workspace does not need to be specified.

### Options

* `-ssh-name ID`

The name of the SSH key to show.

* `-ssh-id ID`

The ID of the SSH key to show.

