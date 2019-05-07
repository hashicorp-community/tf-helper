# The Terraform Helper

The `tfh` program in this repository provides commands for performing
operations relating to [HashiCorp Terraform](https://www.terraform.io/). The
operations include interacting with Terraform Enterprise (TFE) and also
reporting on and manipulating other Terraform artifacts.

Terraform Enterprise API: https://www.terraform.io/docs/enterprise/api/index.html

In particular, the `tfe pushconfig` and `tfe pushvars` commands replaces and
extends the functionality of the deprecated `terraform push` command. You can
use it to upload configurations, start runs, and change and retrieve variables
using the new Terraform Enterprise API. These scripts are not necessary to use
Terraform Enterprise's core workflows, but they offer a convenient interface
for manual actions on the command line.

The `tfh` commands are written in POSIX Bourne shell and so should be used on
UNIX, Linux, and MacOS systems. Use on Windows requires a POSIX compatible
environment such as the [Windows Subsystem for Linux
(WSL)](https://docs.microsoft.com/en-us/windows/wsl/about) or
[Cygwin](https://www.cygwin.com/).

Extensive debugging output is provided by setting the `TF_LOG` environment
variable to any non-empty value, such as `TF_LOG=1`.

## Installation

Ensure that you have the `curl`, `jq`, and `readlink` commands installed. Clone
this repository to a convenient place on your local machine and do one of the
following:

- Add the `tfh/bin` directory to your `PATH` environment variable. For example:

  ```
  git clone git@github.com:hashicorp-community/tf-helper.git
  cd tfh-helper/tfh/bin
  echo "export PATH=$PWD:\$PATH" >> ~/.bash_profile
  ```
- Symlink the `tfh/bin/tfh` executable into a directory that's already included
  in your `PATH`. For example:

  ```
  git clone git@github.com:hashicorp-community/tf-helper.git
  cd tf-helper/tfh/bin
  ln -s $PWD/tfh /usr/local/bin/tfh
  ```
- Run the `tfh` command with its full path. (For example:
  `/usr/local/src/tf-helper/tfh/bin/tfe pushconfig`)

The default branch of this repository is `release`. Development occurs in the
non-default branch `master`. When a release is made, `release` will be updated
to the stable release, and a pull on the default branch will upgrade from
stable release to stable release.

## Getting started

The `tfh` program has some subcommands that can be used without any configuration, however most of the subcommands of interest require configuring access to Terraform Enterprise. There are four ways to configure `tfh` for TFE use.

* Use `-token TOKEN` with each `tfh` run.
* Export the environment varible `TFH_token`: `export TFH_token=TOKEN`
* Put the line `TFH_token=TOKEN` in the configuration file located at `~/.tfh/tfhrc`
* Create a `curlrc` in the configuration directory located at `~/tfh/curlrc`

The recommended method for setting the TFE token is to use a `curlrc` file. This way the token value will not be exposed in the process list. The `curlrc` file can be generated from the `~/.terraformrc` file using the command `tfh curl-config -tfrc`, or from a token value with `tfh curl-config -curltoken TOKEN`. If configuring access to a private TFE instance, then when generating the `curlrc` file from a `.terraformrc` file the `-hostname` common option needs to be set to the hostname of the private isntance. A file can also be manually created with the contents:

```
--header "Authorization: Bearer TOKEN_GOES_HERE"
```

If, instead, the configuration file option is desired, then either the line can be inserted manually into `~/.tfh/tfhrc`, or the `tfh config` command can be used to manipulate the configuration file. To set the token with `tfh config`, run `tfh config -token TOKEN`.

Similar options are available for setting the TFE organization and workspace. For the organization:

* Configuration file entry of `TFH_org=org_name` in `~/.tfh/tfhrc`
* Environment variable `export TFH_org=org_name`
* Command line option `-org org_name`

For the TFE workspace:

* Configuration file entry of `TFH_name=ws_name` in `~/.tfh/tfhrc`
* Environment variable `export TFH_name=ws_name`
* Command line option `-name ws_name`

**NOTE** that `-name` has a different meaning than in previous implementations. This naming is in line with terminology that is in use going forward. This terminology is used with Terraform 0.12 and the `remote` backend: `organization` (shortened to `org`), `name` for _just the workspace portion_, and there is also an optional `-prefix` option to mirror the `remote` backend's prefix setting.

Finally, if `tfh` is being configured to connect to a private TFE instance, then the hostname for the instance also needs to be configured:

* Configuration file entry of `TFH_hostname=host` in `~/.tfh/tfhrc`
* Environment variable `export TFH_hostname=host`
* Command line option `-hostname host`

Note that the hostname should _not_ start with `https://`. That will be prepended and an `address` shell variable will be created in the code.

## Subcommands

Each subcommand is documented individually. See the [documentation
directory](https://github.com/hashicorp-community/tf-helper/tree/master/tfh/usr/share/doc/tfh)
for each subcommand's full description. Some subcommands are documented with
extended descriptions and examples that are not included in the help output at
the command line.

Use the `tfh help` subcommand to list syntax and options for each subcommand at
the command line.

A sample of commands that are available:

- `tfh pushconfig` — Upload a Terraform configuration to a TFE workspace and
  begin a run.
- `tfh pushvars` — Set variables in a TFE workspace.
- `tfh pullvars` — Get variables from a TFE workspace and write them to stdout.
- `tfh workspace` — Create, list, show, delete, and update workspaces
- `tfh ssh` — Manage ssh keys for a TFE organization.

## Caching

Output such as `tfh help` and other internally used artifacts are cached. Sometimes it may be necessary to view or clear the cache. To do this, use the `tfh cache` and `tfh cache -clear` commands.

## Plugins

Plugin support is still under development, however at least simple plugins are functional and can allow for extending `tfe` locally, without the need to have subcommands merged into the main repository. To develop a plugin named `my_plugin`:

* Create the directory `~/.tfh/plugins/my_plugin`
* Create the Markdown file for the command `~/.tfh/plugins/tfh_my_plugin.md`
* Create the shell file for the command implementation `~/.tfh/plugins/tfh_my_plugin.sh`

In order for the files to be found, they must currently be named with the same name as the program: `tfh_`. The plugin directory name does not need to start with the program name.

In the Markdown file, put a `tfh subcommand` style documentation:

```
## `tfh my_plugin`

Short description

### Description

Long description

### Positional parameters

* `FOO`

Documentation for positonal parameter `FOO`.

* `-bar BAR`

Documentation for option `-bar`.

* `-baz=1`

Documentation for boolean flag `-baz`, with default `1`, or true.

```

The shell implementation file should contain a function with the subcommand name, `tfh_my_plugin`.

```
tfh_my_plugin () {
  foo="$1"
  bar="$2"
  baz="$3"

  # common options have been extracted by the tfh argument filter function
  echo "org:      $name"
  echo "name:     $name"
  echo "token:    $token"
  echo "hostname: $hostname"
  echo "address:  $address"
  echo
  echo "foo: $foo"
  echo "bar: $bar"
  echo "baz: $baz"
}
```

The `tfh` command uses [junonia](https://github.com/fprimex/junonia), and subcommands can use any of the configuration items described there - positional parameters, options, booleans, and multi-options.

The following now works:

```
$ tfh help
NAME
  tfh -- Perform operations relating to HashiCorp Terraform
<--- snip --->
SUBCOMMANDS
<--- snip --->
  my_plugin       Short description                                           

$ tfh my_plugin help
NAME
  tfh my_plugin -- Short description

DESCRIPTION
  Long description

PARAMETERS
  FOO             Documentation for positonal parameter `FOO`.                

OPTIONS
  -bar BAR        Documentation for option `-bar`.                            

  -baz=1          Documentation for boolean flag `-baz`, with default `1`, or 
                  true.                                                       

$ tfh my_plugin
org:      tfe_demo
name:     tfe_demo
token:    
hostname: app.terraform.io
address:  https://app.terraform.io

foo: 
bar: 
baz: 1
```
