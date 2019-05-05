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

tfh_workspace_show () {
  # Ensure all of org, etc, are set. Workspace is not required.
  if ! check_required org tfh_token address; then
    return 1
  fi

  echodebug "API request to show workspace:"
  url="$address/api/v2/organizations/$org/workspaces/$ws"
  if ! show_resp="$(tfh_api_call "$url")"; then
    echoerr "Error showing workspace information for $ws"
    return 1
  fi

  printf "%s" "$show_resp" | jq -r '
    "name              = " + .data.attributes.name,
    "id                = " + .data.id,
    "auto-apply        = " + (.data.attributes."auto-apply"|tostring),
    "queue-all-runs    = " + (.data.attributes."queue-all-runs"|tostring),
    "locked            = " + (.data.attributes.locked|tostring),
    "created-at        = " + .data.attributes."created-at",
    "working-directory = " + .data.attributes."working-directory",
    "terraform-version = " + .data.attributes."terraform-version"'
}
