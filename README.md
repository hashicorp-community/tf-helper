# Terraform Enterprise Push

Terraform Enterprise API: https://www.terraform.io/docs/enterprise/api/index.html

The scripts in this repository replace and extend the functionality of the
deprecated `terraform push` command. You can use them to upload configurations,
start runs, and change variables using the new Terraform Enterprise API.
These scripts are not necessary to use Terraform Enterprise's core workflows,
but they offer a convenient interface for manual actions on the command line.

These scripts are written in POSIX Bourne shell and so should be used on UNIX,
Linux, and MacOS systems. Use on Windows requires a POSIX compatible
environment such as the [Windows Subsystem for Linux
(WSL)](https://docs.microsoft.com/en-us/windows/wsl/about) or
[Cygwin](https://www.cygwin.com/).

All scripts support extensive debugging output by setting the `TF_LOG`
environment variable to any non-empty value, such as `TF_LOG=yes`.

## Installation

Ensure that you have the `curl` and `jq` commands installed. Clone this
repository to a convenient place on your local machine and do one of the
following:

- Add the `bin` directory to your `PATH` environment variable. For example:

  ```
  git clone git@github.com:hashicorp/terraform-enterprise-push.git
  cd terraform-enterprise-push/bin
  echo "export PATH=$PWD:\$PATH" >> ~/.bash_profile
  ```
- Symlink the `bin/tfe` executable into a directory that's already included in
  your `PATH`. For example:

  ```
  git clone git@github.com:hashicorp/terraform-enterprise-push.git
  cd terraform-enterprise-push/bin
  ln -s $PWD/tfe /usr/local/bin/tfe
  ```
- Run the `tfe` command with its full path. (For example:
  `/usr/local/src/terraform-enterprise-push/bin/tfe pushconfig`)

We recommend keeping these scripts up to date by regularly running `git pull`.

## Actions

This repository includes three subcommands:

- `tfe pushconfig` — Upload a Terraform configuration to a workspace and begin
  a run.
- `tfe pushvars` — Set variables in a Terraform Enterprise workspace.
- `tfe pullvars` — Get variables from a Terraform Enterprise workspace and write
  them to stdout.

There's also a `tfe help` subcommand to list syntax and options for each
subcommand.

### Push Terraform Configurations

Use `tfe pushconfig -name <ORGANIZATION>/<WORKSPACE> [CONFIG_DIR]` to upload a
Terraform configuration to a workspace and begin a run.

See `tfe help pushconfig` for more information and usage details.

If you've used `terraform push` with the legacy version of Terraform Enterprise,
here are the important differences to notice:

- If the root configuration references modules on the local filesystem, you must
  ensure those modules are included in the configuration directory you push.
  `tfe pushconfig` won't automatically upload modules from outside the targeted
  configuration directory. See the example below for details.

- If the configuration references remote modules (via the module registry or via
  VCS repositories), you can let TFE retrieve them during the run or you can use
  the `-upload-modules` option to include the `.terraform/modules` directory in
  the upload.

- `tfe pushconfig` does not read the remote configuration name from an `atlas`
  block in the configuration. You have to provide it with the `-name` option or
  with the `TFE_ORG` and `TFE_WORKSPACE` environment variables.

- `tfe pushconfig` does not upload providers or pin provider versions; Terraform
  Enterprise always downloads providers during the run. Use Terraform's built-in
  support for [pinning provider versions][pin] by setting `version` in the
  provider configuration block.

[pin]: https://www.terraform.io/docs/configuration/providers.html#provider-versions


#### Example

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

The old `terraform push` command would target the `infrastructure/env/prod` directory; the new `tfe pushconfig` command would target the `infrastructure` directory, in order to include the local modules in the `modules`  directory. You would need to use Terraform Enterprise's UI to configure the workspace to use the `env/prod` subdirectory as the configuration root.

Old push command:

```
# If run from the root of the repository
[infrastructure]$ terraform push env/prod

# If run from the root module of the configuration
[infrastructure/env/prod]$ terraform push
```

New push command (note that `-name` must be specified):

```
# If run from the root of the repository
[infrastructure]$ tfe pushconfig -name org_name/workspace_name

# If run from anywhere else on the filesystem
[anywhere]$ tfe pushconfig -name org_name/workspace_name path/to/infrastructure
```


### Push Terraform Variables and Environment Variables

Use `tfe pushvars` to create and modify variables in a Terraform Enterprise
workspace.

See `tfe help pushvars` for detailed usage options.

Like `terraform push`, `tfe pushvars` can set Terraform variables that are
strings as well as HCL lists and maps. To set strings use `-var` and to set HCL
lists and maps use `-hcl-var`. Also, environment variables can be set
using `-env-var`. Each option has a "sensitive" counterpart for creating
write-only variables. These options are `-svar`, `-shcl-var`, and `-senv-var`.

You can also specify a tfvars file to read from with the `-var-file` option, and
you can load `terraform.tfvars` and `*.auto.tfvars` files from a configuration
directory by specifying the directory as the command's last argument. (Use `.`
if you want to load automatic variables from the current working directory.)
Files are loading using the `terraform console` command.

The variable manipulation logic follows the earlier `terraform push` behavior.
By default, it skips variables that already have a value in Terraform
Enterprise; to replace existing values, use the `-overwrite <NAME>` option.

The `-dry-run` option can show what changes would be made if the command were
run. Use it to avoid surprises, especially if you are loading variables from
multiple sources.

When a configuration directory *is not* provided, no configuration is inspected
for variable information even if the present working directory contains a
configuration. This makes it possible to use `tfe pushvars` completely
independent of a Terraform configuration.

#### Examples

```
# Create Terraform variable 'foo' if it does not exist.
tfe pushvars -name org_name/workspace_name -var 'foo=bar'

# Output a dry run of what would be attempted when running the above command.
tfe pushvars -name org_name/workspace_name -var 'foo=bar' -dry-run

# Set the environment variable CONFIRM_DESTROY to 1 to enable destroy plans.
tfe pushvars -name org_name/workspace_name -env-var 'CONFIRM_DESTROY=1`

# Create Terraform variable 'foo' if it does not exist, overwrite its value
# with 'bar' if it does exist.
tfe pushvars -name org_name/workspace_name -var 'foo=bar' -overwrite foo

# Create (but don't overwrite) a sensitive HCL variable that is a list and a
# non-sensitive HCL variable that is a map.
tfe pushvars -name org_name/workspace_name \
  -shcl-var 'my_list=["one", "two"]' \
  -hcl-var 'my_map={foo="bar", baz="qux"}'

# Create all variables from a my.tfvars file, which does not need to exist in
# the workspace. Note that tfvars files can only set non-sensitive variables.
tfe pushvars -name org_name/workspace_name -var-file my.tfvars

# Create any number of variables from my.tfvars, and overwrite one variable if
# it already exists.
tfe pushvars -name org_name/workspace_name -var-file my.tfvars \
  -overwrite foo

# Inspect a configuration in the current directory for variable information;
# create any variables that do not exist in the Terraform Enterprise workspace
# but which have values in the automatically loaded tfvars sources.
tfe pushvars -name org_name/workspace_name .

# Same as above but also specify a -var-file to include, just as when
# specifying -var-file when running terraform apply
tfe pushvars -name org_name/workspace_name -var-file my.tfvars .

# Same as above but add a command line variable which will override anything
# found in the configuration and .tfvars file(s)
tfe pushvars -name org_name/workspace_name -var-file my.tfvars \
  -var 'foo=bar' .
```

### Pull Terraform and Environment Variables

Use `tfe pullvars` to retrieve variable names and values from a Terraform
Enterprise workspace.

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
# in .tfvars format
tfe pullvars -name org_name/workspace_name

# Same as above, but redirect into a tfvars file
tfe pullvars -name org_name/workspace_name > my.tfvars

# Output only the one Terraform variable specified
tfe pullvars -name org_name/workspace_name -var foo

# Output all environment variables from the workspace. Redirect the output.
tfe pullvars -name org_name/workspace_name -env true > workspace.sh

# Output a Terraform variable and an environment variable
tfe pullvars -name org_name/workspace_name -var foo -env-var CONFIRM_DESTROY
```
