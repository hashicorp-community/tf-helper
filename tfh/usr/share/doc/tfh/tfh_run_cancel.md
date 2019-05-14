## `tfh run cancel`

Stop an active run or prevent a pending plan from running.

### Synopsis

    tfh run cancel [RUNID] [-comment COMMENT]

### Description

Request that a running plan be canceled, or that a pending plan have its run canceled.

### Positional parameters

* `RUNID`

ID of the run to be canceled. If omitted, the lastest run with `is-cancelable` action available is canceled.

### Options

* `-m, -message, -comment COMMENT`

An optional explanation for why the run was canceled.
