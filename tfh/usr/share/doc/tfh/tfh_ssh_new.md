## `tfh ssh new, create`

Create a new Terraform Enterprise workspace

### Synopsis

    tfh ssh new [OPTIONS]

### Description

Create a new Terraform Enterprise SSH key.  SSH keys are defined at the organization level. An organization must be specified with the -name argument, the -tfe-org argument, or the TFE_ORG environment variable. A workspace does not need to be specified.

### Options

* `-ssh-name NAME`

The name to be used to identify the SSH key in TFE.

* `-ssh-file KEYFILE`

The SSH private key file.
