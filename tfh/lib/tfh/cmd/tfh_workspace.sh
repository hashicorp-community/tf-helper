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

tfh_workspace () {
  echodebug "exec with help command"
  exec $0 workspace help
}


# Gets the workspace ID given the organization name and workspace name
_fetch_ws_id () {
  echodebug "Requesting workspace information for $1/$2"

  url="$address/api/v2/organizations/$1/workspaces/$2"
  if ! ws_id_resp="$(tfh_api_call "$url")"; then
    echoerr "unable to fetch workspace information for $1/$2"
    return 1
  fi

  if ! ws_id="$(printf "%s" "$ws_id_resp" | jq -r '.data.id')"; then
    echoerr "could not parse response for ID of workspace $1/$2"
    return 1
  fi

  echodebug "Workspace ID: $ws_id"

  echo "$ws_id"
}
