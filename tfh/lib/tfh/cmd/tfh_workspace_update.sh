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
  "data": {
    "attributes": {
      $1
    },
    "type": "workspaces"
  }
}
EOF

echodebug "Payload contents:"
cat $payload 1>&3
}

tfh_workspace_update () {
  up_ws="$prefix$1"
  auto_apply="$2"
  tf_version="$3"
  working_dir="$4"
  vcs_id="$5"
  vcs_branch="$6"
  vcs_submodules="$7"
  oauth_id="$8"
  remove_vcs="$9"
  queue_all_runs="$10"

  payload="$TMPDIR/tfe-migrate-payload-$(junonia_randomish_int)"

  vcs_obj=
  attr_obj=

  if [ -z "$up_ws" ]; then
    if ! check_required ws; then
      echoerr 'For workspace commands, a positional parameter is also accepted:'
      echoerr 'tfh workspace update WORKSPACE_NAME'
      return 1
    else
      up_ws="$ws"
    fi
  fi

  if [ $auto_apply ] && echo "$TFH_CMDLINE" | grep -Eq -- '-auto-apply'; then
        [ "$attr_obj" ] && attr_obj="$attr_obj,"
        attr_obj="$attr_obj \"auto-apply\": \"$auto_apply\""
  fi

  if [ $queue_all_runs ] && echo "$TFH_CMDLINE" | grep -Eq -- '-queue-all-runs'; then
        [ "$attr_obj" ] && attr_obj="$attr_obj,"
        attr_obj="$attr_obj \"queue-all-runs\": \"$queue_all_runs\""
  fi

  if [ -n "$tf_version" ] && echo "$TFH_CMDLINE" | grep -Eq -- '-terraform-version'; then
        [ "$attr_obj" ] && attr_obj="$attr_obj,"
        attr_obj="$attr_obj \"terraform-version\": \"$tf_version\""
  fi

  if [ -n "$working_dir" ] && echo "$TFH_CMDLINE" | grep -Eq -- '-working-dir'; then
        [ "$attr_obj" ] && attr_obj="$attr_obj,"
        attr_obj="$attr_obj \"working-directory\": \"$working_dir\""
  fi

  if [ -n "$vcs_id" ] && echo "$TFH_CMDLINE" | grep -Eq -- '-vcs-id'; then
        [ "$vcs_obj" ] && vcs_obj="$vcs_obj,"
        vcs_obj="$vcs_obj \"identifier\": \"$vcs_id\""
  fi

  if [ -n "$vcs_branch" ] && echo "$TFH_CMDLINE" | grep -Eq -- '-vcs-branch'; then
        [ "$vcs_obj" ] && vcs_obj="$vcs_obj,"
        vcs_obj="$vcs_obj \"branch\": \"$vcs_branch\""
  fi

  if [ -n "$vcs_submodules" ] && echo "$TFH_CMDLINE" | grep -Eq -- '-vcs-submodules'; then
        [ "$vcs_obj" ] && vcs_obj="$vcs_obj,"
        vcs_obj="$vcs_obj \"ingress-submodules\": \"$vcs_submodules\""
  fi

  if [ -n "$oauth_id" ] && echo "$TFH_CMDLINE" | grep -Eq -- '-oauth-id'; then
        [ "$vcs_obj" ] && vcs_obj="$vcs_obj,"
        vcs_obj="$vcs_obj \"oauth-token-id\": \"$oauth_id\""
  fi

  if [ $remove_vcs ] && echo "$TFH_CMDLINE" | grep -Eq -- '-remove-vcs'; then
    vcs_obj=
    [ "$attr_obj" ] && attr_obj="$attr_obj,"
    attr_obj="$attr_obj \"vcs-repo\": null"
  fi

  if [ "$vcs_obj" ]; then
    [ "$attr_obj" ] && attr_obj="$attr_obj,"
    attr_obj="$attr_obj \"vcs-repo\": {$vcs_obj}"
  fi

  make_update_workspace_payload "$attr_obj"
  if [ 0 -ne $? ]; then
    echoerr "Error generating payload file for workspace update"
    return 1
  fi

  echodebug "API request to update workspace:"
  url="$address/api/v2/organizations/$org/workspaces/$up_ws"
  if ! update_resp="$(tfh_api_call --request PATCH -d @"$payload" "$url")"; then
    echoerr "Error updating workspace $org/$up_ws"
    return 1
  fi

  cat "$payload"
  cleanup "$payload"

  echo "Updated workspace $org/$up_ws"
}
