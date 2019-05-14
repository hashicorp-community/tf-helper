## `tfh run show, get`

Show Terraform Enterprise run details

### Synopsis

    tfh run show [RUNID_OR_STATUS]

### Description

Show run details, including properties such as if the run has auto-apply set, the run status, various timestamps, and various permissions.

### Positional parameters

* `RUNID_OR_STATUS`

The ID of the run show or the status of the latest run to show. For example, `tfh run show planned` to see the last successfully planned run.