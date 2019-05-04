## `tfh pullvars`

Get one or more variables and values from a TFE workspace

### Synopsis

    tfh pullvars [OPTIONS]

### Description

Get variables from a Terraform Enterprise workspace and write them to stdout.  Displays Terraform variables in tfvars format and environment variables in shell format.

By default, this command returns all Terraform variables. You can output all environment variables with '-env true', or output specific variables with the -var or -env-var options.

Sensitive variable names are listed with empty values, since sensitive values can't be retrieved.

### Options

* `-var NAME`

Get a Terraform variable from the Terraform Enterprise workspace. This argument can be specified multiple times.

* `-env-var NAME`

Get an environment variable from the Terraform Enterprise workspace. This argument can be specified multiple times.

* `-env`

Whether to get all environment variables instead of Terraform variables. Defaults to false.

