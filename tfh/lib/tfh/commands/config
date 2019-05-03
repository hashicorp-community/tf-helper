#!/bin/sh

## -------------------------------------------------------------------
##
## Copyright (c) 2018 HashiCorp. All Rights Reserved.
##
## This file is provided to you under the Mozilla Public License
## Version 2.0 (the "License"); you may not use this file
## except in compliance with the License.  You may obtain
## a copy of the License at
##
##   https://www.mozilla.org/en-US/MPL/2.0/
##
## Unless required by applicable law or agreed to in writing,
## software distributed under the License is distributed on an
## "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
## KIND, either express or implied.  See the License for the
## specific language governing permissions and limitations
## under the License.
##
## -------------------------------------------------------------------

tfe_config_description () (
    echo "Show and modify the tfe command configuration"
)

tfe_config_help () (
cat << EOF
SYNOPSIS
 tfe config [ -write [true|false] ] [OPTIONS]

DESCRIPTION
 Show and optionally write configuration information to files for tfe. When
 -write is not specified, the configuration that would be used when executing
 commands is shown. The token source is shown rather than the value. The tfe
 configuration file manages the following values:

 TFE_ORG
 TFE_WORKSPACE
 TFE_URL
 TFE_CURL_CONFIG

 Only non-default values are set in the configuration file. The file itself is
 simply sourced at the beginning of tfe execution. The -write option will
 update values in place.

 The curl configuration file is always generated and overwritten if -write is
 specified. The token source can be the ATLAS_TOKEN or TFE_TOKEN environment
 variable, or the -token command line argument, in that order. A curl
 configuration file is already created if there is a .terraformrc and no curl
 configuration file already.
 
OPTIONS
$(tfe_usage_args)

 -write <BOOLEAN>     Write the specified configuration to the specified
                      configuration file.

EOF
)

tfe_config () (
    # Parse options

    while [ -n "$1" ]; do
        should_shift=1

        # If this is a common option it has already been parsed. Skip it and
        # its value.
        if is_common_opt "$1"; then
            shift
            shift
            continue
        fi

        case "$1" in
            -write)
                write="$(assign_bool "$1" "$2")"
                should_shift=${?#0}
                ;;
        esac

        # Shift the parameter
        [ -n "$1" ] && shift

        # Shift the argument. There may not be one if the parameter was a flag.
        [ $should_shift ] && [ -n "$1" ] && shift
    done

    if [ $write ]; then
        # Create/update the .tfe-cli config.

        # Only write TFE_URL if it's not the default value.
        if [ "$tfe_address" = "$tfe_default_address"  ]; then
            url=
        else
            url="$tfe_address"
        fi

        update_sh_config "$tfe_config" "TFE_ORG=$tfe_org" \
            "TFE_WORKSPACE=$tfe_workspace" "TFE_URL=$url"

        # (Re)create / overwrite the .tfe-cli-curl config
        if [ "$tfe_token_via" = '$ATLAS_TOKEN' ] ||
           [ "$tfe_token_via" = '$TFE_TOKEN'   ] ||
           [ "$tfe_token_via" = '-token'       ]; then
            make_tfe_curl_config "$tfe_curl_config" "$tfe_token"
            echo "# Wrote $tfe_curl_config"
        fi
    else
        printf 'TFE_ORG="%s"\n' "$tfe_org"
        printf 'TFE_WORKSPACE="%s"\n' "$tfe_workspace"
        printf 'TFE_URL="%s"\n' "$tfe_address"

        if [ -n "$tfe_token" ]; then
            echo "# TFE_TOKEN set by $tfe_token_via"
        else
            echo "# TFE_TOKEN is unset"
        fi
    fi
)

