## `tfh pushvars`

Upload Terraform and/or environment variables to a TFE workspace

### Synopsis

    tfh pushvars [OPTIONS] [CONFIG_DIR]

### Description

Update variables in a Terraform Enterprise workspace, using values from files or from the command line. By default, this command skips variables that already have a value in Terraform Enterprise; to replace existing values, use the `-overwrite NAME` option.

If a config dir is specified, pushvars loads the `terraform.tfvars` and `*.auto.tfvars` files in that directory and adds them to the variables set on the command line. If the config dir is omitted, pushvars only uses variables from the command line.

All `-var` style args (except `-var-file`) can be set multiple times to operate on multiple variables with one command.

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

### Extended description

Like `terraform push`, `tfh pushvars` can set Terraform variables that are
strings as well as HCL lists and maps. To set strings use `-var` and to set HCL
lists and maps use `-hcl-var`. Also, environment variables can be set
using `-env-var`. Each option has a "sensitive" counterpart for creating
write-only variables. These options are `-svar`, `-shcl-var`, and `-senv-var`.

A configuration directory can be supplied in the same manner as with `terraform
push`. The configuration will be inspected for default variables, use
automatically loaded tfvars files such as `terraform.tfvars`, and can use
`-var-file` to load any additional tfvars file. Unlike `terraform push` the
configuration directory must be explicitly provided when using a configuration.
If the current directory contains a configuration that should be inspected then
`.` should be supplied as the directory.

The `tfh pushvars` command allows tfvars files and `-var` style arguments to
be used independently, outside the context of any configuration. To operate on
a tfvars file, supply the `-var-file` argument and do not provide any path to a
Terraform configuration. The variables and values in the tfvars file will be
used to create and update variables, along with any additional `-var` style
argument (`-var`, `-svar`, `-env-var`, etc).

The variable manipulation logic for all command variations follows the earlier
`terraform push` behavior.  By default, variables that already exist in
Terraform Enterprise are not created or updated. To overwrite existing values
use the `-overwrite <NAME>` option.

The `-dry-run` option can show what changes would be made if the command were
run. Use it to avoid surprises, especially if you are loading variables from
multiple sources.

#### Examples

```
# Create Terraform variable 'foo' if it does not exist.
tfh pushvars -org org_name -name workspace_name -var 'foo=bar'

# Output a dry run of what would be attempted when running the above command.
tfh pushvars -org org_name -name workspace_name -var 'foo=bar' -dry-run

# Set the environment variable CONFIRM_DESTROY to 1 to enable destroy plans.
tfh pushvars -org org_name -name workspace_name -env-var 'CONFIRM_DESTROY=1'

# Create Terraform variable 'foo' if it does not exist, overwrite its value
# with 'bar' if it does exist.
tfh pushvars -org org_name -name workspace_name -var 'foo=bar' -overwrite foo

# Create (but don't overwrite) a sensitive HCL variable that is a list and a
# non-sensitive HCL variable that is a map.
tfh pushvars -org org_name -name workspace_name \
  -shcl-var 'my_list=["one", "two"]' \
  -hcl-var 'my_map={foo="bar", baz="qux"}'

# Create all variables from a my.tfvars file only. The tfvars file does not
# need to be associated with any Terraform config. Note that tfvars files can
# only set non-sensitive variables.
tfh pushvars -org org_name -name workspace_name -var-file my.tfvars

# Create any number of variables from my.tfvars, and overwrite one variable if
# it already exists.
tfh pushvars -org org_name -name workspace_name -var-file my.tfvars \
  -overwrite foo

# Inspect a configuration in the current directory for variable information;
# create any variables that do not exist in the Terraform Enterprise workspace
# but which may have values in the automatically loaded tfvars sources such as
# terraform.tfvars.
tfh pushvars . -org org_name -name workspace_name

# Same as above but also specify a -var-file to include, just as when
# specifying -var-file when running terraform apply
tfh pushvars . -org org_name -name workspace_name -var-file my.tfvars

# Same as above but add a command line variable which will override anything
# found in the configuration and .tfvars file(s)
tfh pushvars . -org org_name -name workspace_name -var-file my.tfvars \
  -var 'foo=bar'
```
