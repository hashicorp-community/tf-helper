## `tfh pullvars`

Get one or more variables and values from a TFE workspace

### Synopsis

    tfh pullvars [OPTIONS]

### Description

Get variables from a Terraform Enterprise workspace and write them to stdout. Displays Terraform variables in tfvars format and environment variables in shell format.

By default, this command returns all Terraform variables. You can output all environment variables with '-env true', or output specific variables with the -var or -env-var options.

Sensitive variable names are listed with empty values, since sensitive values can't be retrieved.

### Options

* `-var NAME`

Get a Terraform variable from the Terraform Enterprise workspace. This argument can be specified multiple times.

* `-env-var NAME`

Get an environment variable from the Terraform Enterprise workspace. This argument can be specified multiple times.

* `-env`

Whether to get all environment variables instead of Terraform variables. Defaults to false.

### Extended description

Variables stored in a Terraform Enterprise workspace can be retrieved using the
Terraform Enterprise API. The API includes both Terraform and environment
variables. When retrieving variables, Terraform variable output is in `.tfvars`
format, and environment variable output is in shell format. Thus the output is
appropriate for redirecting into a `.tfvars` or `.sh` file. This can be useful
for pulling variables from one workspace and pushing them to another workspace.

Sensitive variables are write-only, so their values cannot be retrieved via the
API. When requested, sensitive variable names are printed with an empty value.

#### Examples

```
# Pull all Terraform variables from a workspace and output them
# in .tfvars format to stdout
tfh pullvars -org org_name -name workspace_name

# Same as above, but redirect into a tfvars file
tfh pullvars -org org_name -name workspace_name > my.tfvars

# Output only the one Terraform variable specified
tfh pullvars -org org_name -name workspace_name -var foo

# Output all environment variables from the workspace. Redirect the output.
tfh pullvars -org org_name -name workspace_name -env true > workspace.sh

# Output a Terraform variable and an environment variable
tfh pullvars -org org_name -name workspace_name -var foo -env-var CONFIRM_DESTROY
```
