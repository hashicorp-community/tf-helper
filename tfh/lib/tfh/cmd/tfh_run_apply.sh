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

tfh_run_apply () {
  run_id="$1"
  comment="$2"

  if ! check_required token address; then
    echoerr "must provide an authentication token and address"
    return 1
  fi

  if [ -z "$run_id" ]; then
    # get the run ID of the last run in a confirmable state and use that
    if ! check_required org ws; then
      echoerr "need org and workspace to locate confirmable run"
      return 1
    fi

    . "$JUNONIA_PATH/lib/tfh/cmd/tfh_workspace.sh"
    if ! ws_id="$(_fetch_ws_id "$org" "$ws")"; then
      return 1
    fi

    echodebug "API request to list runs:"
    url="$address/api/v2/workspaces/$ws_id/runs"
    if ! list_resp="$(tfh_api_call 1 "$url")"; then
      echoerr "failed to list runs for $org/$ws"
      return 1
    fi

    run_id="$(printf "%s" "$list_resp" |
      jq -r '.data[] | select(.attributes.actions."is-confirmable") |
        .id')"

    if [ -z "$run_id" ]; then
      echoerr "unable to locate a confirmable run"
      return 1
    fi
  fi

  echodebug "run id: $run_id"

  payload="{\"comment\":\"$comment\"}"

  for run_id in $run_id; do
    url="$address/api/v2/runs/$run_id/actions/apply"
    if ! apply_resp="$(tfh_api_call -d "$payload" "$url")"; then
      echoerr "unable to apply run $run_id"
      return 1
    fi

    echo "applied run $run_id"
  done
}