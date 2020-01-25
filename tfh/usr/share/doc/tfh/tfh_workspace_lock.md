## `tfh workspace lock`

Lock a Terraform Enterprise workspace

### Synopsis

    tfh workspace lock [OPTIONS]

### Description

Lock a Terraform Enterprise workspace.

### Positional parameters

* `NAME`

Workspace name to lock. Overrides the `-name` common option.

### Options

* `-reason MESSAGE="Locked with tfh"`

Optional message providing a reason for locking the workspace.
