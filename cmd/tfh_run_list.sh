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


tfh_run_list () {
  ws_id="$1"

  if ! check_required org token address; then
    return 1
  fi

  if [ -z "$ws_id" ]; then
    if ! check_required org ws; then
      echoerr "no workspace specified to list runs for"
      return 1
    fi

    . "$JUNONIA_PATH/lib/tfh/cmd/tfh_workspace.sh"
    if ! ws_id="$(_fetch_ws_id "$org" "$ws")"; then
      return 1
    fi

    ws_name="$ws"
  else
    ws_name="$ws_id"
  fi

  echodebug "API request to list runs:"
  url="$address/api/v2/workspaces/$ws_id/runs"
  if ! list_resp="$(tfh_api_call 1 "$url")"; then
    echoerr "failed to list runs for $org/$ws_name"
    return 1
  fi

  listing="$(printf "%s" "$list_resp" | jq -r '
      .data[] |
        [ .id,
          .attributes.status,
          if .attributes.status == "canceled" then
            .attributes."status-timestamps"["force-canceled-at"]
          else
            (.attributes.status + "-at") as $sat |
                  .attributes."status-timestamps"[$sat]
          end,
          .attributes.message
        ] | join(" ")')"

  echo "$listing" | awk '
    {
      $3 = substr($3, 1, 16) "Z"
      printf "%s  %-10s %s  ", $1, $2, $3
      $1 = ""
      $2 = ""
      $3 = ""
      sub(/^ */, "")
      print
    }'
}
