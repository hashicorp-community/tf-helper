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

tfe_unassign_description () (
    echo "Unassign the current SSH key from a Terraform Enterprise workspace"
)

tfe_unassign_help () (
# Be sure to include the common options with tfe_usage_args
cat << EOF
SYNOPSIS
 tfe ssh unassign -name <ORGANIZATION>/<WORKSPACE> [OPTIONS]

DESCRIPTION
 Assign a Terraform Enterprise SSH key to a workspace.

OPTIONS
$(tfe_usage_args)

NOTES
 The curl and jq commands are required.
EOF
)

##
## Helper functions
##

make_unassign_ssh_payload () {

cat > "$payload" <<EOF
{
  "data" : {
    "attributes": {
      "id": null
    },
    "type": "workspaces"
  }
}
EOF

echodebug "[DEBUG] Payload contents:"
cat "$payload" 1>&3
}

tfe_unassign () (
    payload="$TMPDIR/tfe-new-payload-$(random_enough)"

    # Ensure all of the common required variables are set
    if ! check_required; then
        return 1
    fi

    if ! make_unassign_ssh_payload; then
        echoerr "Error generating payload file for SSH key unassignment"
        return 1
    fi

    # Need the workspace ID from the workspace name
    echodebug "[DEBUG] API request to show workspace:"
    url="$tfe_address/api/v2/organizations/$tfe_org/workspaces/$tfe_workspace"
    if ! show_resp="$(tfe_api_call "$url")"; then
        echoerr "Error showing workspace information for $tfe_workspace"
        return 1
    fi

    workspace_id="$(printf "%s" "$show_resp" | jq -r '.data.id')"

    echodebug "[DEBUG] API request for SSH key unassignment:"
    url="$tfe_address/api/v2/workspaces/$workspace_id/relationships/ssh-key"
    if ! unassign_resp="$(tfe_api_call --request PATCH -d @"$payload" "$url")"; then
        echoerr "Error unassigning SSH key from $tfe_workspace"
        return 1
    fi

    cleanup "$payload"

    echo "Unassigned SSH key from $tfe_workspace"
)
