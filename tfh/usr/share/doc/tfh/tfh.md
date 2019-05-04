## `tfh`

Perform operations relating to HashiCorp Terraform

### Description

Details to come

### Options

* `-name NAME`

The name of the Terraform Enterprise workspace, formatted as "<ORGANIZATION>/<WORKSPACE>". If unspecified, uses the TFE_ORG and TFE_WORKSPACE environment variables.

* `-org ORGANIZATION`

The name of the Terraform Enterprise organization. If unspecified, uses the TFE_ORG environment variable.  The -tfh-org and -tfh-workspace can be used as an alternative to specifying -name. The option specified last is the effective value used.

* `-ws WORKSPACE`

The name of the Terraform Enterprise workspace. If unspecified, uses the TFE_WORKSPACE environment variable. The -tfh-org and -tfh-workspace can be used as an alternative to specifying -name. The option specified last is the effective value used.

* `-token TOKEN`

Access token for Terraform Enterprise API requests. If unspecified, uses the ATLAS_TOKEN environment variable.

* `-hostname ADDRESS=app.terraform.io`

The address of your Terraform Enterprise instance. Defaults to the SaaS hostname at https://app.terraform.io

