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

echodebug "Payload contents:"
cat "$payload" 1>&3
}

tfh_ws_new () {
  auto_apply="$1"
  tf_version="$2"
  working_dir="$3"
  vcs_id="$4"
  vcs_branch="$5"
  vcs_submodules="$6"
  oauth_id="$7"
  queue_all_runs="$8"

  payload="$TMPDIR/tfe-new-payload-$(random_enough)"

  # Ensure all of org, etc, are set
  if ! check_required all; then
    return 1
  fi

  # Need oauth if vcs was specified
  if [ -n "$vcs_id" ]; then
    # If no oauth id was given, then see if there is only one and use
    # that one
    if [ -z "$oauth_id" ]; then
      echodebug "API request for OAuth tokens for $org"

      url="$address/api/v2/organizations/$org/oauth-tokens"
      oauth_list_resp="$(tfh_api_call "$url")"

      oauth_id="$(printf "%s" "$oauth_list_resp" | jq -r '.data[] | .id')"
      echodebug "OAuth IDs:"
      echodebug "$oauth_id"

      if [ 1 -ne "$(echo "$oauth_id" | wc -l)" ] || [ -z "$oauth_id" ]; then
        echoerr "Error obtaining a default OAuth ID. Choices are:"

        oauth_clients="$(printf "%s" "$oauth_list_resp" | jq -r '.data[] | .relationships."oauth-client".data.id')"

        echodebug "OAuth client list:"
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

        echodebug "Tokens and clients:"
        echodebug "$tokens_clients"

        echo "$tokens_clients" | while read -r ot_oc; do
          ot="$(echo "$ot_oc" | cut -d ' ' -f 1)"
          oc="$(echo "$ot_oc" | cut -d ' ' -f 2)"

          url="$address/api/v2/oauth-clients/$oc"
          oauth_client_resp="$(tfh_api_call "$url")"

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
  make_new_workspace_payload "$ws" "$auto_apply" "$tf_version" \
                     "$working_dir" "$oauth_id" "$vcs_branch" \
                     "$vcs_submodules" "$vcs_id" "$queue_all_runs"
  if [ 0 -ne $? ]; then
    echoerr "Error generating payload file for workspace creation"
    return 1
  fi

  echodebug "API request for new workspace:"
  url="$address/api/v2/organizations/$org/workspaces"
  if ! new_resp="$(tfh_api_call -d @"$payload" "$url")"; then
    echoerr "Error creating workspace $org/$ws"
    return 1
  fi

  cleanup "$payload"

  echo "Created new workspace $org/$ws"
}
