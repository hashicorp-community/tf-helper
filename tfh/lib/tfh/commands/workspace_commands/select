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

tfe_select_description () (
    echo "Set TFE_WORKSPACE in the tfe-cli configuration file"
)

tfe_select_help () (
# Be sure to include the common options with tfe_usage_args
cat << EOF
SYNOPSIS
 tfe workspace select WORKSPACE_NAME

DESCRIPTION

 Selecting a Terraform Enterprise workspace edits the tfe-cli configuration
 file, setting the TFE_WORKSPACE variable to the specified value. The workspace
 must exist in TFE. To set TFE_WORKSPACE to a non-existent name (for the
 purpose of, for example, using tfe workspace new), use tfe config.

 This behavior mimics terraform workspace select. The workspace cannot be
 specified via any other source than the single named argument.

 An organization must be specified via the environment, configuration file, or
 command argument.

OPTIONS
$(tfe_usage_args)

NOTES
 The curl and jq commands are required.

 An asterisk in the listing indicates the Terraform Enterprise workspace
 currently specified by -name, -tfe-workspace, or the TFE_WORKSPACE
 environment variable.

EOF
)

tfe_select () (
    if [ -z "$1" ]; then
        echoerr "Exactly one argument required: workspace name"
        return 1
    fi

    if [ ! -f "$cmd_dir/list" ]; then
        echoerr "Cannot load required command for select:"
        echoerr "$cmd_dir/list"
        return 1
    fi

    . "$cmd_dir/list"

    if ! workspace_list="$(tfe_list)"; then
        # An error from tfe_list should have been printed
        return 1
    fi

    if ! echo "$workspace_list" | grep -E "^[\* ] $1$" >/dev/null 2>&1; then
        echoerr "Workspace not found: $1"
        return 1
    fi

    # Write the workspace configuration
    if err="$(update_sh_config "$tfe_config" "TFE_WORKSPACE=$1")"; then
        echo "Switched to workspace: $1"
    else
        echoerr "$err"
    fi
)
