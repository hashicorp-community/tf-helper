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

tfe_list_description () (
    echo "List Terraform Enterprise workspaces for an organization"
)

tfe_list_help () (
# Be sure to include the common options with tfe_usage_args
cat << EOF
SYNOPSIS
 tfe workspace list [OPTIONS]

DESCRIPTION
 List Terraform Enterprise workspaces for an organization. An organization
 must be specified with the -name argument, the -tfe-org argument, or
 the TFE_ORG environment variable. Specifying a workspace is optional. If
 a workspace is specified with the -name argument, the -tfe-workspace
 argument, or the TFE_WORKSPACE environment variable it will be preceded
 by an asterisk.

OPTIONS
$(tfe_usage_args)

NOTES
 The curl and jq commands are required.

 An asterisk in the listing indicates the Terraform Enterprise workspace
 currently specified by -name, -tfe-workspace, or the TFE_WORKSPACE
 environment variable.

EOF
)

tfe_list () (
    # Ensure all of tfe_org, etc, are set. Workspace is not required.
    if ! check_required tfe_org tfe_token tfe_address; then
        return 1
    fi

    echodebug "[DEBUG] API request to list workspaces:"
    url="$tfe_address/api/v2/organizations/$tfe_org/workspaces"
    if ! list_resp="$(tfe_api_call "$url")"; then
        echoerr "Error listing workspaces for $tfe_org"
        return 1
    fi

    listing="$(printf "%s" "$list_resp" |
        jq -r --arg ws "$tfe_workspace" '
            .data[]
                | if .attributes.name == $ws then
                      "* " + .attributes.name
                  else
                      "  " + .attributes.name
                  end')"

    # Produce the listing, sorted. Sort on the third character of each line
    # as each is indented two spaces and there may be one marked with an *.
    echo "$listing" | sort -k 1.3
)
