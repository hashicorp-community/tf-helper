## 0.1.0 (January 22, 2019)

NOTES

* Begin tracking versions and changes.

FEATURES

* Command aliases: `create` can be used instead of `new`, and `get` can be used instead of `show`.
* Bool flags: bool arguments can be specified as, e.g., `-arg true`, `-arg 1`, or `-arg`. Some retrictions apply, such as specifying a switch without an argument at the end of, e.g., `pushconfig`, which can expect a directory positional argument at the end.

ENHANCEMENTS

* **New `pushvars` arguments:** `-delete`, `-delete-env`, `-overwrite`, and `-overwrite-all`
* **New commands:** `ssh assign/delete/list/new/show/unassign/update`

BUG FIXES

* `pushvars` now interprets raw HCL `true` and `false`, in addition to `"true"`, `"False"`, `"1"`, and `"0"`.
* `workspace new` was mishandling default OAuth detection when more than one OAuth connection is defined. Now it probably detects this situation and prints a helpful list of OAuth connections that can be chosen for the `-oauth-id` argument.
* Excessive supression of some `find` command output in `pushconfig` resulted in the TFE modules directory not being uploaded.
