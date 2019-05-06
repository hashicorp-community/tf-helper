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

tfh_workspace_delete () {
  # Positional workspace value
  del_ws="$prefix$1"

  if [ -z "$del_ws" ]; then
    if ! check_required ws; then
      echoerr 'For workspace commands, a positional parameter is also accepted:'
      echoerr 'tfh workspace delete WORKSPACE_NAME'
      return 1
    else
      del_ws="$ws"
    fi
  fi

  # Ensure that the rest of the required items have values
  if ! check_required org token address; then
    return 1
  fi

  echodebug "API request to delete workspace:"
  url="$address/api/v2/organizations/$org/workspaces/$del_ws"
  if ! tfh_api_call -X DELETE "$url" >/dev/null; then
    echoerr "Error deleting workspaces $org/$del_ws"
    return 1
  fi

  echo "Deleted $org/$del_ws"
}
