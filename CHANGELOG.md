## 0.3.0 (unreleaed)

## 0.2.3 (May 8, 2019)

BUG FIXES

* Fix for One True AWK limitation by bumping junonia to 1.0.2, where it could not accept a multi-line string as a variable via `-v`. Instead, the value is passed as an argument, then read and deleted from the ARGV as is done in several other places.

## 0.2.2 (May 8, 2019

* NOTES

* Re-enabled caching, forgotten as part of the release process.

## 0.2.1 (May 8, 2019)

BUG FIXES

* Update junonia to 1.0.1 to fix help output.

## 0.2.0 (May 7, 2019)

NOTES

* Port of `tfe-cli` to [junonia](https://github.com/fprimex/junonia). Starting with a clean slate.
* Please read the new documentation!
* The `-name` parameter is now just the workspace name. Use `-org` with `-name`.
* All positional parameters must come before options. This moves the configuration directories to after the `pushvars` and `pushconfig` commands.
* It's now possible to use a curlrc configuration file to authenticate.
* See the new `curl-config`, `config`, and `cache` commands as they are new.

