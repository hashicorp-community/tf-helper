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

echodebug "Payload contents:"
cat "$payload" 1>&3
}

tfh_ssh_unassign () (
  unassign_ws="$1"

  if [ -z "$unassign_ws" ]; then
    if ! check_required ws; then
      echoerr 'A positional parameter is also accepted for this command:'
      echoerr 'tfh ssh unassign WORKSPACE_NAME'
      return 1
    else
      unassign_ws="$ws"
    fi
  fi

  payload="$TMPDIR/tfe-new-payload-$(junonia_randomish_int)"

  # Ensure all of the common required variables are set
  if ! check_required org token address; then
    return 1
  fi

  if ! make_unassign_ssh_payload; then
    echoerr "Error generating payload file for SSH key unassignment"
    return 1
  fi

  # Need the workspace ID from the workspace name
  echodebug "API request to show workspace:"
  url="$address/api/v2/organizations/$org/workspaces/$unassign_ws"
  if ! show_resp="$(tfh_api_call "$url")"; then
    echoerr "Error showing workspace information for $unassign_ws"
    return 1
  fi

  workspace_id="$(printf "%s" "$show_resp" | jq -r '.data.id')"

  echodebug "API request for SSH key unassignment:"
  url="$address/api/v2/workspaces/$workspace_id/relationships/ssh-key"
  if ! unassign_resp="$(tfh_api_call --request PATCH -d @"$payload" "$url")"; then
    echoerr "Error unassigning SSH key from $unassign_ws"
    return 1
  fi

  cleanup "$payload"

  echo "Unassigned SSH key from $unassign_ws"
)
