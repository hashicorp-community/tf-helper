## `tfh run apply`

Confirm a pending plan to allow the run to proceed.

### Synopsis

    tfh run apply [RUNID] [-comment COMMENT]

### Description

Request that a pending run have its plan applied.

### Positional parameters

* `RUNID`

ID of the run to be applied. If omitted, the lastest run with `is-confirmable` action available is applied.

### Options

* `-m, -message, -comment COMMENT`

An optional comment to be passed to the approved plan.
