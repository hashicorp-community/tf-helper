## `tfh`

Perform operations relating to HashiCorp Terraform

### Synopsis

    tfh [SUBCOMMANDS] [PARAMETERS] [OPTIONS]

### Description

Perform operations relating to HashiCorp Terraform artifacts (configurations, states) and services (Terraform Enterprise).

### Options

* `-org ORGANIZATION`

The name of the Terraform Enterprise organization.

* `-name WORKSPACE_NAME`

The name of the Terraform Enterprise workspace.

* `-prefix WORKSPACE_PREFIX`

Terraform Enterprise workspace prefix. Used when working with multiple workspaces in a single configuration.

* `-token TOKEN`

Access token for Terraform Enterprise API requests. Use of a `curlrc` file is encouraged to keep tokens out of environment variables and the process list.

* `-curlrc FILEPATH`

Curl configuration file providing an access token for Terraform Enterprise API requests. This file can be managed using the `tfh curl-config` command.

* `-hostname HOSTNAME=app.terraform.io`

The address of your Terraform Enterprise instance. Defaults to the SaaS hostname at https://app.terraform.io

* `-v, -verbose`

Enable verbose messages.

* `-vv, -vverbose`

Enable very verbose messages.

* `-vvv, -vvverbose`

Enable very, very verbose messages.

