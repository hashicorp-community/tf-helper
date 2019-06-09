## 0.x.x (unreleaed)

## 0.2.5 (June 8, 2019)

BUG FIXES:

* Fix `curl-config` parameter check [#2](https://github.com/hashicorp-community/tf-helper/pull/2)
* Bump junonia to 1.0.4
  - Fixes `dash` on Ubuntu issue whereby a bug in that shell believes junonia contains an arithmatic expansion where there is none [#3](https://github.com/hashicorp-community/tf-helper/issues/3)
  - Fixes `tfh` reported as an unknown parameter issue [#4](https://github.com/hashicorp-community/tf-helper/issues/4)
  - Fixes subcommand alias issues

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

