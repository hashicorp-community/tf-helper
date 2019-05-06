## `tfh ssh update`

Modify a Terraform Enterprise workspace

### Synopsis

    tfh ssh update [OPTIONS]

### Description

Update a Terraform Enterprise SSH key.  SSH keys are defined at the organization level. An organization must be specified with the -name argument, the -tfe-org argument, or the TFE_ORG environment variable. A workspace does not need to be specified.

### Options

* `-ssh-name NAME`

The name of the SSH key in TFE to update.

* `-ssh-id ID`

The ID of the SSH key to update.

* `-ssh-new-name NAME`

The name to rename the SSH key to.

* `-ssh-file KEYFILE`

SSH private key file.

