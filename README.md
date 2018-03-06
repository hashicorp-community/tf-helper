# Terraform Enterprise Push

Terraform Enterprise API: https://www.terraform.io/docs/enterprise/api/index.html

The Terraform Enterprise Push repository hosts scripts that replace and extend
the functionality that was previously provided by the `terraform push` command.
Where `terraform push` was used to upload configurations and perform variable
manipulations in Terraform Enterprise Legacy environments, these scripts can be
used to do the same (and more) using the new Terraform Enterprise API.

These scripts are written in POSIX Bourne shell and so should be used on UNIX,
Linux, and MacOS systems. Use on Windows requires a POSIX compatible
environment such as the [Windows Subsystem for Linux
(WSL)](https://docs.microsoft.com/en-us/windows/wsl/about) or
[Cygwin](https://www.cygwin.com/).

All scripts support extensive debugging output by setting the `TF_LOG`
environment variable to any non-empty value, such as `TF_LOG=1`.

## Installation of the scripts

The Terraform Enterprise Push scripts will execute properly when referred to by
an absolute path (`/path/to/tfe-push-config`), a relative path
(`../terraform-enterprise-push/tfe-push-config`), or by being copied or
symlinked to a directory in the `PATH` environment variable
(`tfe-push-config`).

It is recommended that the scripts be kept up to date with regular `git pull`
operations. One recommended method of installation is to clone this repository
and then add the `bin` path to the path environment variable.

```
git clone git@github.com:hashicorp/terraform-enterprise-push.git
cd terraform-enterprise-push/bin

# For BASH profile
echo "export $PWD" >> ~/.bash_profile

# Re-source or log out / back in to the console
. ~/.bash_profile

# For BASH rc file
echo "export $PWD" >> ~/.bashrc
. ~/.bashrc
```

Another recommended method of installation is to clone this repository and then
place symlinks in a `PATH` directory such as `/usr/local/bin`.

```
git clone git@github.com:hashicorp/terraform-enterprise-push.git
cd /usr/local/bin
ln -s /path/to/terraform-enterprise-push/bin/* .
```

## Push Terraform configurations

Use `tfe-push-config` to upload a Terraform configuration to a workspace and
begin a run.

### Description

There are important differences between `terraform push` with
legacy and `tfe-push-config`.

* The target directory provided to the script should be the directory
  containing all required configuration files and files. Previously with
  `terraform push` the directory specified was the directory containing the
  root configuration module. See the example below for more explanation.

* The `-name` parameter is required for `tfe-push-config` since the backend
  configuraiton is not parsed or used to detect the target workspace.

* Provider version pinning is not supported via `-upload-modules true`.
  Terraform supports [pinning provider
  versions](https://www.terraform.io/docs/configuration/providers.html#provider-versions)
  in the provider configuration block using the `version` parameter. The
  `tfe-push-config` script does not attempt to inspect the configuration for
  this information nor does it inspect the `.terraform/plugins` directory, so
  providers will be retrieved during the run according to the configuration.
  Modules *will* be uploaded because (1) the entire base directory containing
  any local modules should be uploaded, and (2) the `.terraform/modules`
  directory will be uploaded. If `-upload-modules` is `false`, then
  `.terraform` is excluded entirely and `terraform init` will retrieve both
  providers and modules as usual according to the configuration.

See `tfe-push-config -h` for more information and usage details.

### Example: Push a configuration

Given the following repository layout:

```
infrastructure
├── env
│   ├── dev
│   │   └── dev.tf
│   └── prod
│       └── prod.tf
└── modules
    ├── mod1
    │   └── mod1.tf
    └── mod2
        └── mod2.tf
```

With `terraform push` and Terraform Enterprise Legacy, the `env/prod` directory
would have been supplied as the argument even if `env/prod/prod.tf`
instantiated `modules/mod1`.

```
# Old terraform push command for this configuration.

# If run from the root of the repository
[infrastructure]$ terraform push env/prod

# If run from the root module of the configuration
[infrastructure/env/prod]$ terraform push
```

With `tfe-push-config`, the `infrastructure` directory containing _all_ of the
configuration files, including the root module and other modules, would be
specified.

```
# New tfe-push-config command for this configuration. Note again that -name is
# always specified.

# If run from the root of the repository
[infrastructure]$ tfe-push-config -name org_name/workspace_name

# If run from anywhere else on the filesystem
[anywhere]$ tfe-push-config -name org_name/workspace_name path/to/infrastructure
```

### Example: Push a configuration and poll the resulting run

Additionally, `tfe-push-config` can poll the run resulting from the
configuration upload. Polling will continue until a non-active status such as
"errored" or "planned" occurs.

```
# Upload the configuration to start a run, then poll the run every 5s.
[infrastructure]$ tfe-push-config -name org_name/workspace_name -poll 5
```

## Push Terraform variables and environment variables

Use `tfe-push-vars` to create and modify variables in a Terraform Enterprise
workspace. This script replaces and extends the variable manipulation features
of the `terraform push` command used with Terraform Enterprise Legacy.

### Description

Like `terraform push`, `tfe-push-vars` can set Terraform variables that are
strings as well as HCL lists and maps. To set strings use `-var` and to set HCL
lists and maps use `-hcl-var`. Also, environment variables may also be set
using `-env-var`. Each option has a "sensitive" counterpart for creating the
variables with the "sensitive", write-only option enabled for the variable.
These options are `-svar`, `-shcl-var`, and `-senv-var`.

The variable manipulation logic follows the earlier `terraform push` behavior.
If a variable is specified on the command line or discovered from a
configuration or `.tfvars` file, then it will be created in the workspace if it
does not exist and it will be modified if it does exist and `-overwrite` is
specified for the variable. If the variable exists and `-overwrite` is *not*
specified, then the variable will not be overwritten. The update / overwrite
logic also applies when `tfe-push-vars` is run with a `-var-file` specified, or
with a configuration directory specified.

A `-dry-run` option is supplied to show what changes would be made if the
command were run. Please use this option liberally to ensure that variables
are, for example, detected properly from the correct sources: command line,
`.tfvars`, configurations, and automatic variables files with configurations.

When a configuration directory *is not* provided, no configuration is inspected
for variable information even if the present working directory contains a
configuration. This makes it possible to use `tfe-push-vars` completely
independent of a Terraform configuration. Variables can be specified on the
command line and also using `-var-file` with a `.tfvars` file. When using a
`.tfvars` file, it will be inspected for variables and their values using the
`terraform console` command and the results found will follow the earlier
described logic.

When a configuration directory *is* provided, the configuration is inspected
for variables and values using `terraform console`, potentially combined with a
`.tfvars` file, potentially combined with automatic variables files such as
`terraform.tfvars`, and potentially combined with variables specified on the
command line. The results then follow the earlier described logic. Note that a
configuration variable must be *explicitly* provided. If the present working
directory should be inspected, then `.` should be specified.

See `tfe-push-vars -h` for detailed usage options.

### Examples of pushing variable values

```
# Create Terraform variable 'foo' if it does not exist.
tfe-push-vars -name org_name/workspace_name -var 'foo=bar'

# Output a dry run of what would be attempted when running the above command.
tfe-push-vars -name org_name/workspace_name -var 'foo=bar' -dry-run

# Set the environment variable CONFIRM_DESTROY to 1 to enable destroy plans.
tfe-push-vars -name org_name/workspace_name -env-var 'CONFIRM_DESTROY=1`

# Create Terraform variable 'foo' if it does not exist, overwrite its value
# with 'bar' if it does exist.
tfe-push-vars -name org_name/workspace_name -var 'foo=bar' -overwrite foo

# Create or overwrite a sensitive HCL variable that is a list and a
# non-sensitive HCL variale that is a map.
tfe-push-vars -name org_name/workspace_name \
  -shcl-var 'my_list=["one", "two"]' \
  -hcl-var 'my_map={foo="bar", baz="qux"}'

# Create all variables from my.tfvars that do not exist in the workspace.
# Note that all .tfvars variables are non-sensitive.
tfe-push-vars -name org_name/workspace_name -var-file my.tfvars

# Create or overwrite one variable from my.tfvars.
tfe-push-vars -name org_name/workspace_name -var-file my.tfvars \
  -overwrite foo

# Inspect a configuration in the current directory for variable information
# and create any variables that do not exist that have values, which may
# come from automatically loaded tfvars sources.
tfe-push-vars -name org_name/workspace_name .

# Same as above but also specify a -var-file to include, just as when
# specifying -var-file when running terraform apply
tfe-push-vars -name org_name/workspace_name -var-file my.tfvars .

# Same as above but add a command line variable which will override anything
# found in the configuration and .tfvars file(s)
tfe-push-vars -name org_name/workspace_name -var-file my.tfvars \
  -var 'foo=bar' .
```

## Pull Terraform and environment variables

Use `tfe-pull-vars` to retrieve variable names and values from a Terraform
Enterprise workspace.

### Description

Variables stored in a Terraform Enterprise workspace can be retrieved using the
Terraform Enterprise API. The API includes both Terraform and environment
variables. When retrieving variables, Terraform variable output is in `.tfvars`
format, and environment variable output is in shell format. Thus the output is
appropriate for redirecting into a `.tfvars` or `.sh` file. This can be useful
for pulling variables from one workspace and pushing them to another workspace.

Sensitive variables are write-only so their values cannot be retrieved via the
API. Therefore, when specified for retrieval, any sensitive variable name will
be output with an empty value.

### Example of pulling different variables from a workspace

```
# Pull all Terraform variables from a workspace and output them
# in .tfvars format
tfe-pull-vars -name org_name/workspace_name

# Same as above, but redirect into a tfvars file
tfe-pull-vars -name org_name/workspace_name > my.tfvars

# Output only the one Terraform variable specified
tfe-pull-vars -name org_name/workspace_name -var foo

# Output all environment variables from the workspace. Redirect the output.
tfe-pull-vars -name org_name/workspace_name -env true > workspace.sh

# Output a Terraform variable and an environment variable
tfe-pull-vars -name org_name/workspace_name -var foo -env-var CONFIRM_DESTROY
```
