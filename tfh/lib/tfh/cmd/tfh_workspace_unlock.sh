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

tfh_workspace_unlock () {
  # Positional workspace value
  lock_ws="$prefix$1"

  # Force unlock option
  force="$2"

  if [ -z "$lock_ws" ]; then
    if ! check_required ws; then
      echoerr 'For workspace commands, a positional parameter is also accepted:'
      echoerr 'tfh workspace lock WORKSPACE_NAME'
      return 1
    else
      lock_ws="$ws"
    fi
  fi

  # Ensure that the rest of the required items have values
  if ! check_required org token address; then
    return 1
  fi

  . "$JUNONIA_PATH/lib/tfh/cmd/tfh_workspace.sh"
  if ! workspace_id="$(_fetch_ws_id "$org" "$lock_ws")"; then
    return 1
  fi

  if [ $force ]; then
    url="$address/api/v2/workspaces/$workspace_id/actions/force-unlock"
    unlock_err="force-unlocking"
    unlock_msg="Force-unlocked"
  else
    url="$address/api/v2/workspaces/$workspace_id/actions/unlock"
    unlock_err="unlocking"
    unlock_msg="Unlocked"
  fi

  echodebug "API request to lock workspace:"
  if ! tfh_api_call -X POST "$url" >/dev/null; then
    echoerr "Error $unlock_err workspace $org/$lock_ws"
    return 1
  fi

  echo "$unlock_msg $org/$lock_ws"
}
