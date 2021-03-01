## `tfh workspace update`

Modify a Terraform Enterprise workspace

### Synopsis

    tfh workspace update [OPTIONS]

### Description

Modify a Terraform Enterprise workspace.

### Positional parameters

* `NAME`

Workspace name to show. Overrides the `-name` common option.

### Options

* `-auto-apply`

Specifies if, upon a successful plan, the workspace should automatically run an apply. Defaults to false.

* `-terraform-version X.Y.Z`

The version of Terraform that the workspace should use to perform runs. Defaults to the latest Terraform release at the time of workspace creation.

* `-working-dir DIRECTORY`

The directory relative to the root of the VCS repository where the 'terraform' command should be run. Defaults to the root of the VCS repository. To set this to an empty string, it is easiest to use an empty variable, as passing any combination of quotes will be either wrong or fail to pass any value. For example, using `-working-dir $empty` correctly passes a null value / empty string.

* `-vcs-id ID`

The name of the VCS repository ID. Typically in a format similar to "<VCS_ORG_NAME>/<VCS_REPO>".

* `-vcs-branch BRANCH`

The name of the VCS branch to use. Defaults to being unspecified so that defalt branch is used.

* `-vcs-submodules`

If true, when the configuration is ingressed from the VCS service VCS submodules will be retrieved as well.  Defaults to false.

* `-oauth-id ID`

The OAuth ID to be used with the VCS integration.

* `-remove-vcs`

Remove the VCS integration.

* `-queue-all-runs`

If true, runs will be queued immediately after workspace creation. If false, runs will not queue until a run is manually queued first. Defaults to false.

