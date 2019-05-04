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

##
## Helper functions
##

make_update_workspace_payload () {
cat > "$payload" << EOF
{
  "data" : {
    "attributes": {
      $1
    },
    "type": "workspaces"
  }
}
EOF

echodebug "[DEBUG] Payload contents:"
cat $payload 1>&3
}

ws_update () (
    payload="$TMPDIR/tfe-migrate-payload-$(random_enough)"
    auto_apply=false
    queue_all_runs=false
    tf_version=
    working_dir=
    vcs_id=
    vcs_branch=
    vcs_submodules=
    oauth_id=

    vcs_obj=
    attr_obj=

    # Ensure all of org, etc, are set
    if ! check_required all; then
        return 1
    fi

    # Parse options

    while [ -n "$1" ]; do
        should_shift=1

        # If this is a common option it has already been parsed. Skip it and
        # its value.
        if is_common_opt "$1"; then
            shift
            shift
            continue
        fi

        case "$1" in
            -auto-apply)
                auto_apply="$(assign_bool "$1" "$2")"
                should_shift=${?#0}

                # Need auto_apply to be either 'true' or 'false' so
                # it can be passed directly into the payload
                if [ $auto_apply ]; then
                    auto_apply=true
                else
                    auto_apply=false
                fi

                [ "$attr_obj" ] && attr_obj="$attr_obj,"
                attr_obj="$attr_obj \"auto-apply\": \"$auto_apply\""
                ;;
            -queue-all-runs)
                queue_all_runs="$(assign_bool "$1" "$2")"
                should_shift=${?#0}

                if [ $queue_all_runs ]; then
                    queue_all_runs=true
                else
                    queue_all_runs=false
                fi

                [ "$attr_obj" ] && attr_obj="$attr_obj,"
                attr_obj="$attr_obj \"queue-all-runs\": \"$queue_all_runs\""
                ;;
            -terraform-version)
                tf_version=$(assign_arg "$1" "$2")
                [ "$attr_obj" ] && attr_obj="$attr_obj,"
                attr_obj="$attr_obj \"terraform-version\": \"$tf_version\""
                ;;
            -working-dir)
                working_dir=$(assign_arg "$1" "$2")

                # A hyphen means 'set the workspace back to ""' (root of repo)
                if [ "$working_dir" = "-" ]; then
                    working_dir=
                fi

                [ "$attr_obj" ] && attr_obj="$attr_obj,"
                attr_obj="$attr_obj \"working-directory\": \"$working_dir\""
                ;;
            -vcs-id)
                vcs_id=$(assign_arg "$1" "$2")
                [ "$vcs_obj" ] && vcs_obj="$vcs_obj,"
                vcs_obj="$vcs_obj \"identifier\": \"$vcs_id\""
                ;;
            -vcs-branch)
                vcs_branch=$(assign_arg "$1" "$2")
                [ "$vcs_obj" ] && vcs_obj="$vcs_obj,"
                vcs_obj="$vcs_obj \"branch\": \"$vcs_branch\""
                ;;
            -vcs-submodules)
                vcs_submodules=$(assign_bool "$1" "$2")

                if [ $auto_apply ]; then
                    vcs_submodules=true
                else
                    vcs_submodules=false
                fi

                [ "$vcs_obj" ] && vcs_obj="$vcs_obj,"
                vcs_obj="$vcs_obj \"ingress-submodules\": \"$vcs_submodules\""
                ;;
            -oauth-id)
                oauth_id=$(assign_arg "$1" "$2")
                [ "$vcs_obj" ] && vcs_obj="$vcs_obj,"
                vcs_obj="$vcs_obj \"oauth-token-id\": \"$oauth_id\""
                ;;
            *)
                echoerr "Unknown option: $1"
                return 1
                ;;
        esac

        # Shift the parameter
        [ -n "$1" ] && shift

        # Shift the argument. There may not be one if the parameter was a flag.
        [ $should_shift ] && [ -n "$1" ] && shift
    done

    if [ "$vcs_obj" ]; then
        [ "$attr_obj" ] && attr_obj="$attr_obj,"
        attr_obj="$attr_obj \"vcs-repo\" {$vcs_obj}"
    fi

    make_update_workspace_payload "$attr_obj"
    if [ 0 -ne $? ]; then
        echoerr "Error generating payload file for workspace update"
        return 1
    fi

    echodebug "[DEBUG] API request to update workspace:"
    url="$address/api/v2/organizations/$org/workspaces/$ws"
    if ! update_resp="$(tfh_api_call --request PATCH -d @"$payload" "$url")"; then
        echoerr "Error updating workspace $org/$ws"
        return 1
    fi

    cleanup "$payload"

    echo "Updated workspace $org/$ws"
)
