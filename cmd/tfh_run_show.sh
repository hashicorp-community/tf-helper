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

tfh_run_show () {
  run_id="$2"

  if [ -z $run_id ]; then
    if ! check_required; then
      echoerr "need org and workspace to locate latest run to show"
      return 1
    fi

    # Use the list command to retrieve the latest runs
    . "$JUNONIA_PATH/lib/tfh/cmd/tfh_run_list.sh"

    if ! listing="$(tfh_run_list)"; then
      # The listing command will have printed error messages.
      return 1
    fi

    if ! run_id="$(printf "%s" "$listing" | awk 'NR==1 {print $1; exit}')"; then
      echoerr "could not parse run list from $org/$ws for latest run ID"
      return 1
    fi
  fi

  url="$address/api/v2/runs/$run_id"
  run_show="$(tfh_api_call "$url")"

  if [ -n "$run_show" ]; then
    printf "%s" "$run_show" | jq -r '
      [ .data.id,
        .data.attributes.status,
        (.data.attributes.status + "-at") as $sat |
              .data.attributes."status-timestamps"[$sat],
        .data.attributes.message
      ] | join("  ")'
  else
    echoerr "unable to get run details for $run_id"
    return 1
  fi
}
