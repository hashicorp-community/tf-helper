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

make_new_sv_payload () {

# $1 new state version encoded body
# $2 new state version serial number
# $3 new state version lineage
# $4 new state md5 sum

cat > "$payload" <<EOF
{
  "data": {
    "type": "state-versions",
    "attributes": {
      "state": "$1",
      "serial": "$2",
      "lineage": $3,
      "md5": "$4"
    }
  }
}
EOF

echodebug "Payload contents:"
cat "$payload" 1>&3
}

tfh_sv_new () (
  state_path="$1"

  payload="$TMPDIR/tfh-new-payload-$(junonia_randomish_int)"

  if ! check_required; then
    return 1
  fi

  md5="md5sum"
  if ! command -v md5sum >/dev/null 2>&1; then
    if ! command -v md5 >/dev/null 2>&1; then
      echoerr "Either md5sum or md5 command is required"
      return 1
    fi
    md5="md5 -q"
  fi

  if [ ! -f "$state_path" ]; then
    echoerr "File not found: $state_path"
    return 1
  else
    if ! state_serial="$(jq '.serial' "$state_path")"; then
      echoerr "Could not determine state serial from $state_path"
      return 1
    fi

    if ! state_lineage="$(jq '.lineage' "$state_path")"; then
      echoerr "Could not determine state lineage from $state_path"
      return 1
    fi

    if ! state_data="$(uuencode -m "$state_path" "$(basename "$state_path")" \
                       | awk 'NR != 1 && ! /^=/ { printf $0 }')"; then
      echoerr "Unable to encode state file $state_path"
      return 1
    fi

    if ! state_md5="$($md5 "$state_path")"; then
      echoerr "Could not compute md5sum of file $state_file"
      return 1
    fi
    state_md5="${state_md5% *}"
  fi

  . "$JUNONIA_PATH/lib/tfh/cmd/tfh_workspace.sh"
  if ! workspace_id="$(_fetch_ws_id "$org" "$ws")"; then
    return 1
  fi

  if ! make_new_sv_payload "$state_data" "$state_serial" "$state_lineage" "$state_md5"; then
    echoerr "Error generating payload file for state version creation"
    return 1
  fi

  echodebug "API request for new state version:"
  url="$address/api/v2/workspaces/$workspace_id/state-versions"
  if ! new_resp="$(tfh_api_call -d @"$payload" "$url")"; then
    echoerr "Error creating state version"
    return 1
  fi

  cleanup "$payload"

  echo "Created new state version"
)
