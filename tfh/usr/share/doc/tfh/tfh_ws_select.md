## `tfh ws select`

Set `TFH_workspace` in the tfh configuration file

### Synopsis

    tfh ws select WORKSPACE_NAME

### Description

Selecting a Terraform Enterprise workspace edits the tfe-cli configuration file, setting the TFE_WORKSPACE variable to the specified value. The workspace must exist in TFE. To set TFE_WORKSPACE to a non-existent name (for the purpose of, for example, using tfe workspace new), use tfe config.

This behavior mimics terraform workspace select. The workspace cannot be specified via any other source than the single named argument.

An organization must be specified via the environment, configuration file, or command argument.

An asterisk in the listing indicates the Terraform Enterprise workspace currently specified by -name, -tfe-workspace, or the TFE_WORKSPACE environment variable.

### Positional parameters

* `WORKSPACE_NAME`

Name of the workspace to set in the configuration file.
