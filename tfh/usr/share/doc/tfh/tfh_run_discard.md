## `tfh run discard`

Skip remaining operations on a paused run

### Synopsis

    tfh run discard [RUNID] [-comment COMMENT]

### Description

Skip remaining operations on a paused run such that it can no longer be acted on.

### Positional parameters

* `RUNID`

ID of the run to be discarded. If omitted, the lastest run with the `is-discardable` action available is discarded.

### Options

* `-m, -message, -comment COMMENT`

An optional explanation for why the run was discarded.
