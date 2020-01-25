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

tfh_sv_show () {
  show_sv="$1"

  . "$JUNONIA_PATH/lib/tfh/cmd/tfh_workspace.sh"
  if ! workspace_id="$(_fetch_ws_id "$org" "$ws")"; then
    return 1
  fi

  if [ -z "$show_sv" ]; then
    if ! check_required token address; then
      return 1
    fi
    url="$address/api/v2/workspaces/$workspace_id/current-state-version"
  else
    url="$address/api/v2/state-versions/$show_sv"
  fi

  echodebug "API request to show workspace:"
  if ! show_resp="$(tfh_api_call "$url")"; then
    echoerr "Error showing state version information for $show_sv"
    return 1
  fi

  printf "%s" "$show_resp" | jq -r '
    "id                        = " + .data.id,
    "serial                    = " + (.data.attributes.serial|tostring),
    "created-at                = " + .data.attributes."created-at",
    "vcs-commit-url            = " + .data.attributes."vcs-commit-url",
    "vcs-commit-sha            = " + .data.attributes."vcs-commit-sha",
    "hosted-state-download-url = " + .data.attributes."hosted-state-download-url"'
}
