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

tfe_workspace_description () (
    echo "Perform operations on workspaces"
)

tfe_workspace_help () (
    cmd_dir="$cmd_dir/workspace_commands"

    # Be sure to include the common options with tfe_usage_args
    cat << EOF
SYNOPSIS
 tfe workspace <SUBCOMMAND>

DESCRIPTION
 Perform a variety of operations on workspaces, where subcommand is one
 of the following:

$(list_cmd_descriptions)

EOF
)

tfe_workspace () (
    execute_subcmd $bin_name "$cmd_dir/workspace_commands" "$@"
)
