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

tfe_show () (
    ssh_name=
    ssh_id=

    # Parse options

    while [ -n "$1" ]; do
        # If this is a common option it has already been parsed. Skip it and
        # its value.
        if is_common_opt "$1"; then
            shift
            shift
            continue
        fi

        case "$1" in
            -ssh-name)
                ssh_name=$(assign_arg "$1" "$2")
                ;;
            -ssh-id)
                ssh_id=$(assign_arg "$1" "$2")
                ;;
            *)
                echoerr "Unknown option: $1"
                return 1
                ;;
        esac

        # Shift the parameter and argument
        [ -n "$1" ] && shift
        [ -n "$1" ] && shift
    done

    if [ -z "$ssh_name" ] && [ -z "$ssh_id" ]; then
        echoerr "One of -ssh-name or -ssh-id is required"
        return 1
    fi

    # Use the list command to retrieve all keys, then narrow down
    # the output to the one of interest.
    . "$cmd_dir/list"

    if ! listing="$(tfe_list)"; then
        # The listing command will have printed error messages.
        return 1
    fi

    ssh_show="$(echo "$listing" | awk -v name="$ssh_name" -v id="$ssh_id" '
         name && $1 == name;
         id && $2 == id')"

    if [ -n "$ssh_show" ]; then
        echo "$ssh_show"
    else
        echoerr "SSH key not found"
        return 1
    fi
)
