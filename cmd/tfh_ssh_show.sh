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

tfh_ssh_show () (
  ssh_name="$1"
  ssh_id="$2"

  if [ -z $ssh_name$ssh_id ]; then
    exec $0 ssh show help
    return 1
  fi

  # Use the list command to retrieve all keys, then narrow down
  # the output to the one of interest.
  . "$JUNONIA_PATH/lib/tfh/cmd/tfh_ssh_list.sh"

  if ! listing="$(tfh_ssh_list)"; then
    # The listing command will have printed error messages.
    return 1
  fi

  ssh_show="$(echo "$listing" | awk -v name="$ssh_name" -v id="$ssh_id" '
     name && $1 == name;
     id && $2 == id')"

  if [ -n "$ssh_show" ]; then
    echo "$ssh_show"
  else
    echoerr "SSH key not found"
    return 1
  fi
)
