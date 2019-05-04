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

tfh_config () (
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
        if [ "$address" = "$tfh_default_address"  ]; then
            url=
        else
            url="$address"
        fi

        update_sh_config "$tfh_config" "TFE_ORG=$org" \
            "TFE_WORKSPACE=$ws" "TFE_URL=$url"

        # (Re)create / overwrite the .tfe-cli-curl config
        if [ "$tfh_token_via" = '$ATLAS_TOKEN' ] ||
           [ "$tfh_token_via" = '$TFE_TOKEN'   ] ||
           [ "$tfh_token_via" = '-token'       ]; then
            make_tfh_curl_config "$tfh_curl_config" "$tfh_token"
            echo "# Wrote $tfh_curl_config"
        fi
    else
        printf 'TFE_ORG="%s"\n' "$org"
        printf 'TFE_WORKSPACE="%s"\n' "$ws"
        printf 'TFE_URL="%s"\n' "$address"

        if [ -n "$tfh_token" ]; then
            echo "# TFE_TOKEN set by $tfh_token_via"
        else
            echo "# TFE_TOKEN is unset"
        fi
    fi
)
