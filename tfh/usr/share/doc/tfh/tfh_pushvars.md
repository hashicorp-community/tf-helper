## `tfh pushvars`

Upload Terraform and/or environment variables to a TFE workspace

### Synopsis

    tfh pushvars [OPTIONS] [CONFIG_DIR]

### Description

Update variables in a Terraform Enterprise workspace, using values from files or from the command line. By default, this command skips variables that already have a value in Terraform Enterprise; to replace existing values, use the '-overwrite <NAME>' option.

If a config dir is specified, pushvars loads the `terraform.tfvars` and `*.auto.tfvars` files in that directory and adds them to the variables set on the command line. If the config dir is omitted, pushvars only uses variables from the command line.

All -var style args (except -var-file) can be set multiple times to operate on multiple variables with one command.

If you specify a config directory to load variables from, it must be a directory where "terraform init" has been run.

The terraform command is required if operating on a tfvars file or a Terraform configuration.

### Positional parameters

* `CONFIG_DIR`

### Options

* `-dry-run`

Show what would be done without changing any variables in the workspace. Defaults to false.

* `-var ASSIGNMENT [-var ASSIGNMENT ...]`

Set a Terraform variable with a basic string value.

* `-svar ASSIGNMENT [-svar ASSIGNMENT ...]`

Set a sensitive Terraform variable with a basic string value.

* `-hcl-var ASSIGNMENT [-hcl-var ASSIGNMENT ...]`

Set a Terraform variable with an HCL value.

* `-shcl-var ASSIGNMENT [-shcl-var ASSIGNMENT ...]`

Set a sensitive Terraform variable with an HCL value.

* `-env-var ASSIGNMENT [-env-var ASSIGNMENT ...]`

Set an environment variable.

* `-senv-var ASSIGNMENT [-senv-var ASSIGNMENT ...]`

Set a sensitive environment variable.

* `-delete NAME [-delete NAME]`

Delete an existing Terraform variable. Can be set multiple times.

* `-delete-env NAME [-delete-env NAME]`

Delete an existing environment variable. Can be set multiple times.

* `-overwrite NAME [-overwrite NAME]`

Overwrite an existing value if the <NAME> Terraform variable is already set in Terraform Enterprise. You must enable this for every variable you want to overwrite. Can be set multiple times.

* `-overwrite-env NAME [-overwrite-env NAME]`

Overwrite an existing value if the <NAME> environment variable is already set in Terraform Enterprise. You must enable this for every variable you want to overwrite. Can be set multiple times.

* `-overwrite-all`

Overwrite the existing value of every variable being operated on if that variable is already set in Terraform Enterprise. Defaults to false. Use with extreme caution.  To perform the overwrites, -dry-run must be explicitly set to false, otherwise a dry run will be performed.

* `-var-file FILE`

Load Terraform variables from a tfvars file. Files can only set non-sensitive variables.

* `-hide-sensitive=1`

Whether to hide sensitive values in output. Defaults to true.
