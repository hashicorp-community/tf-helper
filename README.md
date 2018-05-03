# Terraform Enterprise Command Line Tool

Terraform Enterprise API: https://www.terraform.io/docs/enterprise/api/index.html

The `tfe` command in this repository replaces and extends the functionality of
the deprecated `terraform push` command. You can use it to upload
configurations, start runs, and change and retrieve variables using the new
Terraform Enterprise API.  These scripts are not necessary to use Terraform
Enterprise's core workflows, but they offer a convenient interface for manual
actions on the command line.

These scripts are written in POSIX Bourne shell and so should be used on UNIX,
Linux, and MacOS systems. Use on Windows requires a POSIX compatible
environment such as the [Windows Subsystem for Linux
(WSL)](https://docs.microsoft.com/en-us/windows/wsl/about) or
[Cygwin](https://www.cygwin.com/).

Extensive debugging output is provided by setting the `TF_LOG` environment
variable to any non-empty value, such as `TF_LOG=1`.

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
- `tfe migrate` — Migrate a legacy TFE environment to a new TFE workspace

There's also a `tfe help` subcommand to list syntax and options for each
subcommand.

### Push Terraform Configurations

Use `tfe pushconfig -name <ORGANIZATION>/<WORKSPACE> [CONFIG_DIR]` to upload a
Terraform configuration to a workspace and begin a run.

See `tfe help pushconfig` for more information and usage details.

If you've used `terraform push` with the legacy version of Terraform Enterprise,
here are the important differences to notice:

- `tfe pushconfig` does not read the remote configuration name from an `atlas`
  block in the configuration. It must be provided with the `-name` option or
  with the `TFE_ORG` and `TFE_WORKSPACE` environment variables.

- `tfe pushconfig` does not upload providers or pin provider versions.
  Terraform Enterprise always downloads providers during the run. Use
  Terraform's built-in support for [pinning provider versions][pin] by setting
  `version` in the provider configuration block. Custom providers will be
  uploaded and used if they are tracked by the VCS and placed in the directory
  where `terraform` will be executed.

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

Run any of the following commands to push the `prod` configuration (note that
the workspace name must be specified on the command line with `-name` or using
`TFE_ORG` and `TFE_WORKSPACE`):

```
# If run from the root of the repository
[infrastructure]$ tfe pushconfig -name org_name/workspace_name env/prod

# If run from the prod directory
[prod]$ tfe pushconfig -name org_name/workspace_name

# If run from anywhere else on the filesystem
[anywhere]$ tfe pushconfig -name org_name/workspace_name path/to/infrastructure/env/prod
```

In each of the above commands the contents of the `env/prod` directory
(`prod.tf`) that are tracked by the VCS (git) are archived and uploaded to the
Terraform Enterprise workspace. The files are located using effectively `cd
env/prod && git ls-files`.

If `-vcs false` is specified then all files in `env/prod` are uploaded. If
`-upload-modules false` is specified then the `.terraform/modules` directory
will not be uploaded even if it is present.


### Push Terraform Variables and Environment Variables

Use `tfe pushvars` to create and modify variables in a Terraform Enterprise
workspace.

See `tfe help pushvars` for detailed usage options.

Like `terraform push`, `tfe pushvars` can set Terraform variables that are
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

The `tfe pushconfig` command allows tfvars files and `-var` style arguments to
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
tfe pushvars -name org_name/workspace_name -var 'foo=bar'

# Output a dry run of what would be attempted when running the above command.
tfe pushvars -name org_name/workspace_name -var 'foo=bar' -dry-run

# Set the environment variable CONFIRM_DESTROY to 1 to enable destroy plans.
tfe pushvars -name org_name/workspace_name -env-var 'CONFIRM_DESTROY=1'

# Create Terraform variable 'foo' if it does not exist, overwrite its value
# with 'bar' if it does exist.
tfe pushvars -name org_name/workspace_name -var 'foo=bar' -overwrite foo

# Create (but don't overwrite) a sensitive HCL variable that is a list and a
# non-sensitive HCL variable that is a map.
tfe pushvars -name org_name/workspace_name \
  -shcl-var 'my_list=["one", "two"]' \
  -hcl-var 'my_map={foo="bar", baz="qux"}'

# Create all variables from a my.tfvars file only. The tfvars file does not
# need to be associated with any Terraform config. Note that tfvars files can
# only set non-sensitive variables.
tfe pushvars -name org_name/workspace_name -var-file my.tfvars

# Create any number of variables from my.tfvars, and overwrite one variable if
# it already exists.
tfe pushvars -name org_name/workspace_name -var-file my.tfvars \
  -overwrite foo

# Inspect a configuration in the current directory for variable information;
# create any variables that do not exist in the Terraform Enterprise workspace
# but which may have values in the automatically loaded tfvars sources such as
# terraform.tfvars.
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
# in .tfvars format to stdout
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

### Migrate a Legacy TFE environment to a new TFE workspace

Use the `tfe migrate` command to perform a migration of a Legacy Terraform
Enterprise environment to a new Terraform Enterprise workspace.

See `tfe help migrate` for detailed usage options.

The legacy environment specified must exist and not be locked by any run or
user other than the current user. The environment may either be unlocked or may
be locked already by the user performing the migration. The target workspace
name should not exist, as it will be created.

Please refer to the Terraform Enterprise documentation for [details on the
actions taken during
migration](https://www.terraform.io/docs/enterprise/api/workspaces.html#create-a-workspace-which-is-migrated-from-a-legacy-environment).

A legacy environment name, new workspace name, and VCS repository identifier
must be specified when performing a migration. Additionally, an OAuth token
will be used and can be specified. If only one OAuth client is configured for
the target organization then it will be used and does not need to be specified.

If more than one OAuth client is configured then it is necessary to obtain the
OAuth token ID using the [Terraform Enterprise
API](https://www.terraform.io/docs/enterprise/api/oauth-tokens.html).

Examples:

```
# Migrate an existing legacy environment to a newly created workspace, where
# the workspace has only one OAuth client configured.
$ tfe migrate -legacy-name my_old_org/my_environment \
              -name my_org/my_new_workspace \
              -vcs-id vcs_org_name/vcs_repo
Migration complete: my_old_org/my_environment -> my_org/my_new_workspace

# Migrate and specify the OAuth ID
$ tfe migrate -legacy-name my_old_org/my_environment \
              -name my_org/my_new_workspace \
              -vcs-id vcs_org_name/vcs_repo \
              -oauth-id ot-ATnEXAMPLE7BAAE5
Migration complete: my_old_org/my_environment -> my_org/my_new_workspace
```
