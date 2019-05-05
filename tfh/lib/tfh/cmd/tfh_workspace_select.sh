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

tfh_workspace_select () {
  ws="$1"

  if [ -z "$ws" ]; then
    echoerr "Exactly one argument required: workspace name"
    return 1
  fi

  . "$JUNONIA_PATH/lib/tfh/cmd/tfh_ws_list.sh"

  if ! ws_list="$(tfh_ws_list)"; then
    # An error from tfh_list should have been printed
    return 1
  fi

  if ! echo "$ws_list" | grep -E "^[\* ] $1$" >/dev/null 2>&1; then
    echoerr "Workspace not found: $1"
    return 1
  fi

  # Write the workspace configuration
  if err="$(update_sh_config "$JUNONIA_CONFIG" "TFE_workspace=$ws")"; then
    echo "Switched to workspace: $ws"
  else
    echoerr "$err"
  fi
}
