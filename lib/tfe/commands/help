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

# List all of the commands and their descriptions in the help
list_cmd_descriptions () (
    cd "$cmd_dir"

    for cmd in *; do
        if [ -d $cmd ]; then
            continue
        fi

        . "$cmd_dir/$cmd"
        printf " %-12s%s\n" "$cmd" "$(tfe_${cmd}_description)"
    done
    echo
)

tfe_help_description () (
    echo "Get help on tfe commands"
)

tfe_help_help () (
    if [ -z "$cmd" ]; then

        cat << EOF
SYNOPSIS
 tfe COMMAND [OPTIONS]

DESCRIPTION
 Perform operations in Terraform Enterprise using the API. Command is one of
 the following:

$(list_cmd_descriptions)

EOF

    else

        cat << EOF
SYNOPSIS
 tfe $cmd COMMAND [OPTIONS]

DESCRIPTION
 Get help on a command, where command is one of the following:

$(list_cmd_descriptions)

EOF

    fi
)

tfe_help () (
    if [ $# -eq 0 ]; then
        # Just ran 'tfe help'
        tfe_help_help
        return 0
    else
        # Ran 'tfe help <cmd>'
        cmd=$1
        if [ ! -f "$cmd_dir/$cmd" ]; then
            echoerr "Command $cmd not found. Cannot provide help information."
            return 1
        else
            . "$cmd_dir/$cmd"
            tfe_${cmd}_help
            return $?
        fi
    fi
)
