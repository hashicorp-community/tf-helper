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

make_assign_ssh_payload () {

# $1 SSH key ID

cat > "$payload" <<EOF
{
  "data" : {
  "attributes": {
    "id": "$1"
  },
  "type": "workspaces"
  }
}
EOF

echodebug "Payload contents:"
cat "$payload" 1>&3
}

tfh_ssh_assign () (
  ssh_id="$1"
  ssh_name="$2"
  payload="$TMPDIR/tfe-new-payload-$(random_enough)"

  # Ensure all of the common required variables are set
  if ! check_required; then
    return 1
  fi

  if [ -z "$ssh_name" ] && [ -z "$ssh_id" ]; then
    echoerr "One of -ssh-name or -ssh-id is required"
    return 1
  fi

  if [ -n "$ssh_name" ] && [ -n "$ssh_id" ]; then
    echoerr "Only one of -ssh-name or -ssh-id should be specified"
    return 1
  fi

  if [ -n "$ssh_name" ]; then
    # Use the show command to check for and retrieve the ID of the key
    # in the case of being passed a name.
    . "$cmd_dir/show"

    # Pass the command line arguments to show and get back a key (or error)
    if ! ssh_show="$(tfh_show -ssh-name "$ssh_name")"; then
      # The show command will have printed error messages.
      return 1
    fi

    # Really, if it's empty then tfh_show should have exited non-zero
    if [ -z "$ssh_show" ]; then
      echoerr "SSH key not found"
      return 1
    fi

    ssh_id="$(echo "$ssh_show" | cut -d ' ' -f 2)"
  else
    # To simplify error reporting later, we'll print ssh_show, but if
    # we were given an ID set ssh_show to the ID as it will be empty.
    ssh_show="$ssh_id"
  fi

  # This shouldn't happen...
  if [ -z "$ssh_id" ]; then
    echoerr "SSH key not found"
    return 1
  fi

  if ! make_assign_ssh_payload "$ssh_id"; then
    echoerr "Error generating payload file for SSH key assignment"
    return 1
  fi

  # Need the workspace ID from the workspace name
  echodebug "API request to show workspace:"
  url="$address/api/v2/organizations/$org/workspaces/$ws"
  if ! show_resp="$(tfh_api_call "$url")"; then
    echoerr "Error showing workspace information for $ws"
    return 1
  fi

  workspace_id="$(printf "%s" "$show_resp" | jq -r '.data.id')"

  echodebug "API request for SSH key assignment:"
  url="$address/api/v2/workspaces/$workspace_id/relationships/ssh-key"
  if ! assign_resp="$(tfh_api_call --request PATCH -d @"$payload" "$url")"; then
    echoerr "Error assigning SSH key $ssh_show to $ws"
    return 1
  fi

  cleanup "$payload"

  echo "Assigned SSH key $ssh_show to $ws"
)
