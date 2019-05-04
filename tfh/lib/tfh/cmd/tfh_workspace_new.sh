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

make_new_workspace_payload () {

# $1 new workspace name
# $2 auto-apply
# $3 TF version
# $4 working dir
# $5 oauth token ID
# $6 VCS branch
# $7 vcs submodules
# $8 VCS repo ID (e.g. "github_org/github_repo")
# $9 queue-all-runs

cat > "$payload" <<EOF
{
  "data": {
    "type": "workspaces",
    "attributes": {
EOF

if [ -n "$5" ] && [ -n "$8" ]; then
cat >> "$payload" <<EOF
      "vcs-repo": {
        "identifier": "$8",
        "oauth-token-id": "$5",
        "ingress-submodules": $7,
        "branch": "$6"
      },
EOF
fi

if [ -n "$3" ]; then
cat >> "$payload" <<EOF
      "terraform-version": "$3",
EOF
fi

cat >> "$payload" <<EOF
      "working-directory": "$4",
      "auto-apply": $2,
      "queue-all-runs": $9,
      "name": "$1"
    }
  }
}
EOF

echodebug "[DEBUG] Payload contents:"
cat "$payload" 1>&3
}

tfe_new () (
    payload="$TMPDIR/tfe-new-payload-$(random_enough)"
    auto_apply=false
    queue_all_runs=false
    tf_version=
    working_dir=
    vcs_id=
    vcs_branch=
    vcs_submodules=false
    oauth_id=

    # Ensure all of tfe_org, etc, are set
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
                ;;
            -queue-all-runs)
                queue_all_runs="$(assign_bool "$1" "$2")"
                should_shift=${?#0}

                if [ $queue_all_runs ]; then
                    queue_all_runs=true
                else
                    queue_all_runs=false
                fi
                ;;
            -terraform-version)
                tf_version=$(assign_arg "$1" "$2")
                ;;
            -working-dir)
                working_dir=$(assign_arg "$1" "$2")
                ;;
            -vcs-id)
                vcs_id=$(assign_arg "$1" "$2")
                ;;
            -vcs-branch)
                vcs_branch=$(assign_arg "$1" "$2")
                ;;
            -vcs-submodules)
                vcs_submodules=$(assign_arg "$1" "$2")
                ;;
            -oauth-id)
                oauth_id=$(assign_arg "$1" "$2")
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

    # Need oauth if vcs was specified
    if [ -n "$vcs_id" ]; then
        # If no oauth id was given, then see if there is only one and use
        # that one
        if [ -z "$oauth_id" ]; then
            echodebug "[DEBUG] API request for OAuth tokens for $tfe_org"

            url="$tfe_address/api/v2/organizations/$tfe_org/oauth-tokens"
            oauth_list_resp="$(tfe_api_call "$url")"

            oauth_id="$(printf "%s" "$oauth_list_resp" | jq -r '.data[] | .id')"
            echodebug "[DEBUG] OAuth IDs:"
            echodebug "$oauth_id"

            if [ 1 -ne "$(echo "$oauth_id" | wc -l)" ] || [ -z "$oauth_id" ]; then
                echoerr "Error obtaining a default OAuth ID. Choices are:"

                oauth_clients="$(printf "%s" "$oauth_list_resp" | jq -r '.data[] | .relationships."oauth-client".data.id')"

                echodebug "[DEBUG] OAuth client list:"
                echodebug "$oauth_clients"

                # Given
                # ot-1
                # ot-2
                # ot-3
                # oc-1
                # oc-2
                # oc-3
                # Create
                # ot-1 oc-1
                # ot-2 oc-2
                # ot-3 oc-3
                tokens_clients="$(printf '%s\n%s' "$oauth_id" "$oauth_clients" | awk '
                    /^ot/ {
                        ot[i++]=$0
                    }
                    /^oc/ {
                        print ot[j++], $0
                    }')"

                echodebug "[DEBUG] Tokens and clients:"
                echodebug "$tokens_clients"

                echo "$tokens_clients" | while read -r ot_oc; do
                    ot="$(echo "$ot_oc" | cut -d ' ' -f 1)"
                    oc="$(echo "$ot_oc" | cut -d ' ' -f 2)"

                    url="$tfe_address/api/v2/oauth-clients/$oc"
                    oauth_client_resp="$(tfe_api_call "$url")"

                    printf '%s' "$oauth_list_resp" | \
                        jq -r --arg ID "$ot" '
                            .data []
                            | select(.id == $ID)
                            | "id               = " + .id,
                              "created-at       = " + .attributes."created-at",
                              "user             = " + .attributes."service-provider-user"'

                    printf '%s' "$oauth_client_resp" | jq -r '
                        "oauth-client     = " + .data.id,
                        "created-at       = " + .data.attributes."created-at",
                        "callback-url     = " + .data.attributes."callback-url",
                        "connect-path     = " + .data.attributes."connect-path",
                        "service-provider = " + .data.attributes."service-provider",
                        "display-name     = " + .data.attributes."service-provider-display-name",
                        "http-url         = " + .data.attributes."http-url",
                        "api-url          = " + .data.attributes."api-url",
                        "key              = " + .data.attributes.key,
                        "secret           = " + (.data.attributes.secret|tostring),
                        "rsa-public-key   = " + (.data.attributes."rsa-public-key"|tostring)'

                    echo
                done

                return 1
            fi
        fi
    fi

    # $1 new workspace name
    # $2 auto-apply
    # $3 TF version
    # $4 working dir
    # $5 oauth token ID
    # $6 VCS branch
    # $7 VCS submodules
    # $8 VCS repo ID (e.g. "github_org/github_repo")
    # $9 queue-all-runs
    make_new_workspace_payload "$tfe_workspace" "$auto_apply" "$tf_version" \
                               "$working_dir" "$oauth_id" "$vcs_branch" \
                               "$vcs_submodules" "$vcs_id" "$queue_all_runs"
    if [ 0 -ne $? ]; then
        echoerr "Error generating payload file for workspace creation"
        return 1
    fi

    echodebug "[DEBUG] API request for new workspace:"
    url="$tfe_address/api/v2/organizations/$tfe_org/workspaces"
    if ! new_resp="$(tfe_api_call -d @"$payload" "$url")"; then
        echoerr "Error creating workspace $tfe_org/$tfe_workspace"
        return 1
    fi

    cleanup "$payload"

    echo "Created new workspace $tfe_org/$tfe_workspace"
)
