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

tfh_ws_delete () {
    # Ensure all of org, etc, are set.
    if ! check_required; then
        return 1
    fi

    echodebug "API request to delete workspace:"
    url="$address/api/v2/organizations/$org/workspaces/$ws"
    if ! tfh_api_call -X DELETE "$url" >/dev/null; then
        echoerr "Error deleting workspaces $org/$ws"
        return 1
    fi

    echo "Deleted $org/$ws"
}
