## `tfh workspace new, create`

Create a new Terraform Enterprise workspace

### Synopsis

    tfh workspace new [OPTIONS]

### Description

Create a new Terraform Enterprise workspace. If more than one OAuth client is configured use the OAuth Tokens API to list the clients and their IDs. Provide the appropriate ID from the list to the -oauth-id option.

https://www.terraform.io/docs/enterprise/api/oauth-tokens.html

### Positional parameters

* `NAME`

Workspace name to show. Overrides the `-name` common option.

### Options

* `-auto-apply`

Specifies if, upon a successful plan, the workspace should automatically run an apply. Defaults to false.

* `-terraform-version X.Y.Z`

The version of Terraform that the workspace should use to perform runs. Defaults to the latest Terraform release at the time of workspace creation.

* `-working-dir DIRECTORY`

The directory relative to the root of the VCS repository where the 'terraform' command should be run. Defaults to the root of the VCS repository.

* `-vcs-id ID`

The name of the VCS repository ID. Typically in a format similar to "<VCS_ORG_NAME>/<VCS_REPO>".

* `-vcs-branch BRANCH`

The name of the VCS branch to use. Defaults to being unspecified so that defalt branch is used.

* `-vcs-submodules`

If true, when the configuration is ingressed from the VCS service VCS submodules will be retrieved as well.  Defaults to false.

* `-oauth-id ID`

The OAuth ID, obtained from the Terraform Enterprise API, which corresponds to the VCS ID provided. Defaults to the OAuth ID of the configured client if there is only one.

* `-queue-all-runs`

If true, runs will be queued immediately after workspace creation. If false, runs will not queue until a run is manually queued first. Defaults to false.
