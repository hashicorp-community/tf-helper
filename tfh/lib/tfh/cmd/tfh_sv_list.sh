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

tfh_sv_list () {
  if ! check_required; then
    return 1
  fi

  echodebug "API request to list state versions:"
  url="$address/api/v2/state-versions?filter%5Bworkspace%5D%5Bname%5D=$ws&filter%5Borganization%5D%5Bname%5D=$org"
  if ! list_resp="$(tfh_api_call "$url")"; then
    echoerr "Error listing state versions for $org/$ws"
    return 1
  fi

  listing="$(printf "%s" "$list_resp" |
    jq -r --arg ws "$ws" '.data[] | .id')"

  echo "$listing"
}
