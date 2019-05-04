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

tfe_list () (
    # Ensure all of tfe_org, etc, are set. Workspace is not required.
    if ! check_required tfe_org tfe_token tfe_address; then
        return 1
    fi

    echodebug "[DEBUG] API request to list SSH keys:"
    url="$tfe_address/api/v2/organizations/$tfe_org/ssh-keys"
    if ! list_resp="$(tfe_api_call "$url")"; then
        echoerr "Error listing SSH keys for $tfe_org"
        return 1
    fi

    listing="$(printf "%s" "$list_resp" |
        jq -r '.data[] | .attributes.name + " " + .id')"

    # Sort the listing by name.
    echo "$listing" | sort
)
