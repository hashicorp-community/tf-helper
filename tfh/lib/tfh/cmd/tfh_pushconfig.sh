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

list_vcs () {
  git ls-files
}

list_files () {
  find -L . -type f 2>/dev/null | grep -E -v '^\.$|.git|.terraform'
}

list_modules () {
  find -L .terraform/modules -type f 2>/dev/null |  grep -E -v '^\.$|\.git'
}

list_hardlinked () {
  find -L . -type f -links +1 2>/dev/null | grep -E -v '^\.$|.git|.terraform' | cut -c 3-
}

list_not_hardlinked () {
  find -L . -type f -links 1 2>/dev/null | grep -E -v '^\.$|.git|.terraform' | cut -c 3-
}

list_hardlinked_modules () {
  find -L .terraform/modules -type f -links +1 2>/dev/null |  grep -E -v '^\.$|\.git'
}

list_not_hardlinked_modules () {
  find -L .terraform/modules -type f -links 1 2>/dev/null |  grep -E -v '^\.$|\.git'
}

# Use GNU tar to archive the current directory
gnutar () {
  echodebug "Using GNU tar"

  if [ $vcs ]; then
    list_vcs > "$tarlist"
  else
    list_files > "$tarlist"
  fi

  if [ $upload_modules ]; then
    list_modules >> "$tarlist"
  fi

  tar ${tfh_tar_verbose}zcfh \
    "$1" -T "$tarlist" --hard-dereference
}

# Use BSD tar to archive the current directory
bsdtar () {
  echodebug "Using BSD tar"

  vcslist="$TMPDIR/vcslist-$(junonia_randomish_int)"
  hardlinklist="$TMPDIR/hardlinklist-$(junonia_randomish_int)"

  hardlinks="$(list_hardlinked | sort)"
  echo "$hardlinks" > "$hardlinklist"

  if [ $vcs ]; then
    list_vcs | sort > "$vcslist"
    hardlinks="$(comm -12 "$vcslist" "$hardlinklist")"
  fi

  if [ -z "$hardlinks" ]; then
    # If there are no hardlinks then the job is easy and
    # the same as GNU tar without --hard-dereference
    echodebug "No hardlinks to manually resolve"
    if [ $vcs ]; then
      list_vcs > "$tarlist"
    else
      list_files > "$tarlist"
    fi

    if [ $upload_modules ]; then
      list_modules >> "$tarlist"
    fi

    tar ${tfh_tar_verbose}zcfh \
      "$1" -T "$tarlist"
  else
    # If there are hardlinks they have to be added separately
    # to the archive one by one
    echodebug "Resolving hardlinks manually"

    if [ $vcs ]; then
      # Tracked hardlinks are in the hard link list already.
      # Need tracked non-hardlinks to tar.
      comm -23 "$vcslist" "$hardlinklist" > "$tarlist"
    else
      # Need all of the hardlinks, including ones that might be
      # in the modules dir if uploading modules
      list_hardlinked > "$hardlinklist"

      # Need the non-hardlinks to tar
      list_not_hardlinked > "$tarlist"
    fi

    if [ $upload_modules ]; then
      list_hardlinked_modules >> "$hardlinklist"
      list_not_hardlinked_modules >> "$tarlist"
    fi

    # Start by creating an uncompressed tar of the non-hardlinks
    echodebug "Creating initial tar"
    tar ${tfh_tar_verbose}cfh "${1%.gz}" -T "$tarlist"

    # Add each hardlink to the archive individually
    echodebug "Adding each hardlink"
    cat "$hardlinklist" | while read -r hl; do
      tar ${tfh_tar_verbose}rf "${1%.gz}" "$hl"
    done

    # Compress the completed archive
    echodebug "Compressing ${1%.gz}"
    gzip "${1%.gz}"
  fi
}

make_run_payload () {
cat > "$run_payload" <<EOF
{
"data": {
  "attributes": {
    "is-destroy": ${1:-false},
    "message": "$2"
  },
  "type":"runs",
  "relationships": {
EOF

echodebug "parameters: $1 $3"

if [ ! $1 ] && [ -n "$3" ]; then
cat >> "$run_payload" <<EOF
    "configuration-version": {
    "data": {
      "type": "configuration-versions",
      "id": "$3"
    }
    },
EOF
fi

cat >> "$run_payload" <<EOF
    "workspace": {
    "data": {
      "type": "workspaces",
      "id": "$4"
    }
    }
  }
}
}
EOF
}

tfh_pushconfig () {
  config_dir="$1"
  message="$2"
  destroy="$3"
  current_config="$4"
  upload_modules="$5"
  vcs="$6"
  stream="$7"
  poll="$8"

  if [ $stream ] && [ "$poll" -eq 0 ]; then
    poll=0.5
  fi

  config_id=
  run_payload="$TMPDIR/run-$(junonia_randomish_int).json"
  config_payload="$TMPDIR/content-$(junonia_randomish_int).tar.gz"
  tarlist="$TMPDIR/tarlist-$(junonia_randomish_int)"

  if ! junonia_is_num "$poll"; then
    echoerr "-poll must be a number"
    return 1
  fi

  # Check for additional required commands.
  if ! junonia_require_cmds tar; then
    return 1
  fi

  if tar --version | grep GNU >/dev/null 2>&1; then
    tarcmd=gnutar
  else
    tarcmd=bsdtar

    # Using bsdtar might result in a two step process where first the
    # tar is created and then compressed, which requires the separate
    # gzip command. It may not be strictly required under all
    # circumstances but it's probably better to error earlier rather
    # than later, considering how common the gzip command is.
    if ! junonia_require_cmds gzip; then
      return 1
    fi
  fi

  # Check for required standard options
  if ! check_required; then
    return 1
  fi

  if [ $destroy ] && [ $current_config ]; then
    echoerr "Options -destroy and -current-config conflict"
    return 1
  fi

  . "$JUNONIA_PATH/lib/tfh/cmd/tfh_workspace.sh"
  if ! workspace_id="$(_fetch_ws_id "$org" "$ws")"; then
    return 1
  fi

  if [ ! $destroy ] && [ ! $current_config ]; then
    # Check for additional required commands.
    if [ $vcs ] && ! junonia_require_cmds git; then
      return 1
    fi

    # Creates a tar.gz of the VCS or directory with the configuration

    echodebug "Creating file for upload"

    echodebug "Entering dir $config_dir"
    if ! cd "$config_dir"; then
      echoerr "Unable to change to configuration directory $config_dir"
      return 1
    fi

    if [ $vcs ]; then
      # VCS detection was requested so it must actually be present
      if ! git status >/dev/null 2>&1; then
        echoerr "VCS not present in $config_dir"
        echoerr "Disable VCS detection with -vcs 0"
        return 1
      fi
      echodebug "tar: Uploading vcs tracked files"
      echodebug "excluding any plugins"
    else
      echodebug "tar: Uploading all of $PWD"
      echodebug "excluding VCS files and any plugins"
    fi

    # If there are modules we might want to upload them.
    has_modules="$([ -d .terraform/modules ] && echo 1 || echo )"
    echodebug "Has .terraform/modules: $has_modules"

    $tarcmd "$config_payload"
    if [ $? != 0 ]; then
      echoerr "Error creating config archive payload"
      return 1
    fi

    echo "Uploading Terraform config..."

    echodebug "Creating a new config version for $ws"

    # The JSON Payload used to create the new configuration version
    config_ver_payload='{"data":{"type":"configuration-versions","attributes":{"auto-queue-runs":false}}}'

    echodebug "Creating config version in workspace $workspace_id"

    # Creates the configuration version and extractes the upload-url
    url=$address/api/v2/workspaces/$workspace_id/configuration-versions

    echodebug "URL: $url"

    echodebug "API request for config upload:"
    if ! upload_url_resp="$(tfh_api_call -d "$config_ver_payload" $url)"; then
      echoerr "Error creating config version"
      cleanup "$config_payload" "$tarlist"
      return 1
    fi

    if ! config_id="$(printf "%s" "$upload_url_resp" | jq -r '.data.id')"; then
      echoerr "Error parsing API response for config ID"
      cleanup "$config_payload" "$tarlist"
      return 1
    fi
    echodebug "Config ID: $config_id"

    # Perform the upload of the config archive to the upload URL
    if ! (
      set -e
      url="$(printf "%s" "$upload_url_resp" | jq -r '.data.attributes."upload-url"')"
      echodebug "Upload URL: $url"
      echodebug "Uploading content to upload URL"

      upload_config_resp="$(curl -f $tfh_curl_silent -X PUT --data-binary "@$config_payload" ${url})"

      echodebug "Upload config response:"
      echodebug "$upload_config_resp"
    ) 2>&3; then
      echoerr "Error uploading config archive"
      cleanup "$config_payload" "$tarlist"
      return 1
    fi
    cleanup "$config_payload" "$tarlist"
  fi

  # Submission of the config version and upload of the archive does not mean
  # that the config version is ready for use. It has a status, and it's
  # necessary to poll on that status to make sure that the upload is
  # "uploaded", even if the upload is complete on the client side.
  url="$address/api/v2/configuration-versions/$config_id"
  config_status=
  retries=0
  while [ "$config_status" != "uploaded" ] && [ $retries -lt 3 ]; do
    # Initially don't sleep, and then back off linearly
    sleep $retries
    if config_get_resp="$(tfh_api_call $url)"; then
      config_status="$(printf "%s" "$config_get_resp" | jq -r '.data.attributes.status')"
    fi
    echodebug "Config status: $config_status"
    retries=$(( $retries + 1 ))
  done

  if [ "$config_status" != "uploaded" ]; then
    echoerr "Error creating run. Config status is $config_status after $retries tries"
    return 1
  fi

  make_run_payload "$destroy" "$message" "$config_id" "$workspace_id"
  echodebug "Run payload contents:"
  echodebug "$(cat "$run_payload")"

  url=$address/api/v2/runs
  if ! run_create_resp="$(tfh_api_call -d @"$run_payload" $url)"; then
    echoerr "Error creating run"
    if [ $destroy ]; then
      echoerr "Note: -destroy requires CONFIRM_DESTROY=1 in the workspace"
    fi
    cleanup "$run_payload"
    return 1
  fi
  echodebug "Run create response:"
  echodebug "$run_create_resp"

  run_id="$(printf "%s" "$run_create_resp" | jq -r '.data.id')"

  cleanup "$run_payload"

  echodebug "Run ID: $run_id"

  if [ -z "$run_id" ]; then
    echoerr "Error obtaining run ID"
    return 1
  fi

  printf "Run $run_id submitted to $org/$ws"
  if [ -n "$config_id" ]; then
    printf " using config $config_id"
  fi
  printf "\n"

  # A literal, exact 0 means no polling, so a string comparison is sufficient.
  if [ 0 = "$poll" ]; then
    return 0
  fi

  plan_id="$(printf "%s" "$run_create_resp" | \
             jq -r '.data.relationships.plan.data.id')"
  plan_url="$address/api/v2/plans/$plan_id"
  run_url="$address/api/v2/runs/$run_id"

  # Repeatedly poll the system every N seconds specified with -poll to get
  # the run status until it reaches a non-active status. By default -poll is
  # 0 and there is no polling.
  run_status=pending
  lock_id=
  log_offset=0
  err=0
  stx=0
  etx=0

  # Go until we don't see one of these states
  while [ "$run_status" = pending   ] ||
        [ "$run_status" = planning  ] ||
        [ "$run_status" = applying  ] ||
        [ "$run_status" = confirmed ] ||
        [ "$etx" -ne 1 ] ||
        [ "$err" -eq 0  ]; do
    # if the workspace was determined to be locked in the previous
    # poll, don't delay getting the final status and exiting.
    if [ true != "$ws_locked" ]; then
      sleep $poll
    fi

    echodebug "API request to poll plan:"
    plan_resp="$(tfh_api_call "$plan_url")"
    err=$(( $err + $? ))
    plan_status="$(printf "%s" "$plan_resp" | jq -r '.attributes.status')"
    err=$(( $err + $? ))

    echodebug "API request for run info:"
    run_resp="$(tfh_api_call "$run_url")"
    err=$(( $err + $? ))
    run_status="$(printf "%s" "$run_resp" | jq -r '.data.attributes.status')"
    err=$(( $err + $? ))
    echodebug "$run_status"

    if [ $stream ]; then
      log_read_url="$(printf "%s" "$plan_resp" | jq -r '.data.attributes."log-read-url"')"
      err=$(( $err + $? ))

      echodebug "Log read URL:"
      echodebug "$log_read_url"

      if [ -z "$log_read_url" ] || [ "$log_read_url" = null ]; then
        # Loop and sleep
        continue
      fi

      log_resp="$(tfh_api_call "$log_read_url""?limit=1000&offset=$log_offset")"
      err=$(( $err + $? ))
      log_offset=$(( $log_offset + ${#log_resp} ))
      #printf "%s" "$log_resp"
      # STX: 
      # ETX: 
      logline="$(printf "%s" "$log_resp" | awk -v stx="$stx" '
        BEGIN { ret = 0                }
        //  { sub(//, ""); ret = 2 }
        //  { sub(//, ""); ret = 3 }
        stx   { print                  }
        END   { exit ret               }')"
      case $? in
        1) echoerr "could not process log for printing"; return 1 ;;
        2) stx=1 ;;
        3) etx=1 ;;
      esac
      printf "%s" "$logline"
    else
      echo "$run_status"
    fi

    echodebug "API Request for workspace info $org/$ws"
    url="$address/api/v2/organizations/$org/workspaces/$ws"
    ws_info_resp="$(tfh_api_call "$url")"
    err=$(( $err + $? ))

    ws_locked="$(printf "%s" "$ws_info_resp" | jq -r '.data.attributes.locked')"
    err=$(( $err + $? ))

    if [ true = "$ws_locked" ]; then
      lock_id="$(printf "%s" "$ws_info_resp" | jq -r '.data.relationships."locked-by".data.id')"
      if [ "$lock_id" != "$run_id" ]; then
        echo "locked by $lock_id"
        return 0
      fi
    fi
  done
  echo
  echo "status: $run_status"

  if [ "$err" -gt 0 ]; then
    echoerr "failed to poll run"
    return 1
  fi
}
