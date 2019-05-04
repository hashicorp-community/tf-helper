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

tfh_ssh_delete () (
    # Use the show command to check for and retrieve the ID of the key
    # in the case of being passed a name.
    . "$cmd_dir/show"

    # Pass the command line arguments to show and get back a key (or error)
    if ! ssh_show="$(tfh_show "$@")"; then
        # The show command will have printed error messages.
        return 1
    fi

    # Really, if it's empty then tfh_show should have exited non-zero
    if [ -z "$ssh_show" ]; then
        echoerr "SSH key not found"
        return 1
    fi

    ssh_id="$(echo "$ssh_show" | cut -d ' ' -f 2)"

    echodebug "[DEBUG] API request to delete SSH key:"
    url="$address/api/v2/ssh-keys/$ssh_id"
    if ! tfh_api_call -X DELETE "$url" >/dev/null; then
        echoerr "Error deleting SSH key $ssh_id"
        return 1
    fi

    echo "Deleted SSH key $ssh_show"
)
