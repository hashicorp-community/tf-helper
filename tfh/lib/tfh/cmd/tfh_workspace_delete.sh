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

tfe_delete_description () (
    echo "Delete a Terraform Enterprise workspace"
)

tfe_delete_help () (
# Be sure to include the common options with tfe_usage_args
cat << EOF
SYNOPSIS
 tfe workspace delete -name <ORGANIZATION>/<WORKSPACE> [OPTIONS]

DESCRIPTION
 Delete a Terraform Enterprise workspace

OPTIONS
$(tfe_usage_args)

NOTES
 The curl and jq commands are required.

EOF
)

tfe_delete () (
    # Ensure all of tfe_org, etc, are set.
    if ! check_required; then
        return 1
    fi

    echodebug "[DEBUG] API request to delete workspace:"
    url="$tfe_address/api/v2/organizations/$tfe_org/workspaces/$tfe_workspace"
    if ! tfe_api_call -X DELETE "$url" >/dev/null; then
        echoerr "Error deleting workspaces $tfe_org/$tfe_workspace"
        return 1
    fi

    echo "Deleted $tfe_org/$tfe_workspace"
)
