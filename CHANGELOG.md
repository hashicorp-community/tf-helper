## 0.2.9 (November 24, 2020)

BUG FIXES:

* VCS JSON payload missing a colon
* Add check for explicit JSON `null` in variable value response
* Correctly supply `is-destroy` in `pushconfig`(TylerPinson)

ENHANCEMENTS:

* If a workspace is set to auto-apply, then a pushconfig will follow the apply when polling or streaming


## 0.2.8 (January 7, 2020)

BUG FIXES:

* Set `vcs_submodules` to `false` by default (flaviotorres)
* Numerous `pushvars` fixes (sumitmaggo)
* Fix config pushing logic in `pushconfig` so `-destroy` and `-current-config` work
* Bump junonia to 1.0.8, fixing a regex problem for a particular version of `gawk`

ENHANCEMENTS:

* Support parsing integer values for `pushvars` and other `pushvars` fixes (sumitmaggo)
* Support trimming whitespace around variables and values in `pushvars`
* If `~/.terraformrc` only has one entry, `curl-config` will use that one even if `-hostname` is not specified in some manner, making it more user friendly.

## 0.2.7 (June 11, 2019)

BUG FIXES:

* Small doc fix to `tfh workspace list` and hostname setting env vars
* Bump junonia to 1.0.7
  - Fixes config file values being appended to defaults instead of overwriting them

## 0.2.6 (June 10, 2019)

BUG FIXES:

* Replace last occurrence of `random_enough` with `junonia_randomish_int`
* Bump junonia to 1.0.6
  - Fixes AWK `substr` usage to be compatible with `mawk`

## 0.2.5 (June 9, 2019)

BUG FIXES:

* Fix `curl-config` parameter check [#2](https://github.com/hashicorp-community/tf-helper/pull/2)
* Bump junonia to 1.0.5
  - Fixes `dash` on Ubuntu issue whereby a bug in that shell believes junonia contains an arithmatic expansion where there is none [#3](https://github.com/hashicorp-community/tf-helper/issues/3)
  - Fixes `tfh` reported as an unknown parameter issue [#4](https://github.com/hashicorp-community/tf-helper/issues/4)
  - Fixes subcommand alias issues
  - Fixes spec cache repeatedly adding metacommands
  - Correctly skips attempting to set readonly environment variables when resolving arguments

## 0.2.4 (May 17, 2019)

ENHANCEMENTS:

* Always try to capture and show JSON-API errors for improved error reporting.
* Run commands - cancel, discard, list, show
* Cache is done by version, so each upgrade will not collide.
* New `tfh` options:
  - `-curlrc` to specify the curl config file to use
  - `-vv` for more verbosity
  - `-vvv` for even more verbosity, including outputting the `curl` commands used for API calls.
* Implemented `pushconfig -stream` for streaming back plan logs. It works but could use some improvement.
* Bump junonia to 1.0.3.

BUG FIXES:

* Token sources were not being properly handled as intended. Fixed that and documented the precendence.
* Metacommands (`config`, `cache`...) were not being included in the program argument spec some times.
* Subcommand aliases are always properly respected.
* The mentioned fixes had positive effects on help generation, spec generation, and argument parsing.

## 0.2.3 (May 8, 2019)

BUG FIXES:

* Fix for One True AWK limitation by bumping junonia to 1.0.2, where it could not accept a multi-line string as a variable via `-v`. Instead, the value is passed as an argument, then read and deleted from the ARGV as is done in several other places.

## 0.2.2 (May 8, 2019

NOTES:

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

