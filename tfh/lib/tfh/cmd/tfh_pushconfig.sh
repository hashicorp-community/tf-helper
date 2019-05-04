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
    echodebug "[DEBUG] Using GNU tar"

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
    echodebug "[DEBUG] Using BSD tar"

    vcslist="$TMPDIR/vcslist-$(random_enough)"
    hardlinklist="$TMPDIR/hardlinklist-$(random_enough)"

    hardlinks="$(list_hardlinked | sort)"
    echo "$hardlinks" > "$hardlinklist"

    if [ $vcs ]; then
        list_vcs | sort > "$vcslist"
        hardlinks="$(comm -12 "$vcslist" "$hardlinklist")"
    fi

    if [ -z "$hardlinks" ]; then
        # If there are no hardlinks then the job is easy and
        # the same as GNU tar without --hard-dereference
        echodebug "[DEBUG] No hardlinks to manually resolve"
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
        echodebug "[DEBUG] Resolving hardlinks manually"

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
        echodebug "[DEBUG] Creating initial tar"
        tar ${tfh_tar_verbose}cfh "${1%.gz}" -T "$tarlist"

        # Add each hardlink to the archive individually
        echodebug "[DEBUG] Adding each hardlink"
        cat "$hardlinklist" | while read -r hl; do
            tar ${tfh_tar_verbose}rf "${1%.gz}" "$hl"
        done

        # Compress the completed archive
        echodebug "[DEBUG] Compressing ${1%.gz}"
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

echodebug "[DEBUG] parameters: $1 $3"

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

tfh_pushconfig () (
    upload_modules=1
    vcs=1
    message="Queued via tfe-cli"
    config_dir=.
    config_id=
    poll_run=0
    destroy=
    current_config=
    run_payload="$TMPDIR/run-$(random_enough).json"
    config_payload="$TMPDIR/content-$(random_enough).tar.gz"
    tarlist="$TMPDIR/tarlist-$(random_enough)"

    # Check for additional required commands.
    if [ -z "$(command -v tar)" ]; then
        echoerr "The tar command must be installed"
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
        if [ -z "$(command -v gzip)" ]; then
            echoerr "The gzip command must be installed"
            return 1
        fi
    fi

    # Check for required standard options
    if ! check_required; then
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
            -upload-modules)
                upload_modules="$(assign_bool "$1" "$2")"
                should_shift=${?#0}
                ;;
            -vcs)
                vcs="$(assign_bool "$1" "$2")"
                should_shift=${?#0}
                ;;
            -message)
                message="$(assign_arg "$1" "$2")"
                ;;
            -destroy)
                destroy="$(assign_bool "$1" "$2")"
                should_shift=${?#0}
                ;;
            -current-config)
                current_config="$(assign_bool "$1" "$2")"
                should_shift=${?#0}
                ;;
            -poll)
                if [ "$2" -eq "$2" ] >/dev/null 2>&1; then
                    poll_run=$(assign_arg "$1" "$2")
                else
                    echoerr "-poll must be an integer"
                    return 1
                fi
                ;;
            *)
                # Shouldn't get here until the last option, the optional
                # config directory
                if [ $# -gt 1 ]; then
                    echoerr "Trailing options following config directory $1"
                    return 1
                fi

                config_dir=$1
                ;;
        esac

        # Shift the parameter
        [ -n "$1" ] && shift

        # Shift the argument. There may not be one if the parameter was a flag.
        [ $should_shift ] && [ -n "$1" ] && shift
    done

    if [ $destroy ] && [ $current_config ]; then
        echoerr "Options -destroy and -current-config conflict"
        return 1
    fi

    # Gets the workspace ID given the organization name and workspace name
    workspace_id="$( (
        set -e
        echodebug "[DEBUG] Requesting workspace information for $org/$ws"

        url="$address/api/v2/organizations/$org/workspaces/$ws"
        workspace_id_resp="$(tfh_api_call "$url")"
        echodebug "[DEBUG] Workspace ID response:"
        echodebug "$workspace_id_resp"

        workspace_id="$(printf "%s" "$workspace_id_resp" | jq -r '.data.id')"
        echodebug "[DEBUG] Workspace ID: $workspace_id"

        test -n "$workspace_id"
        echo "$workspace_id"
    ) 2>&3 )"

    if [ 0 -ne $? ]; then
        echoerr "Error obtaining workspace ID"
        return 1
    fi

    if [ ! $destroy ] && [ ! $current_config ]; then
        # Check for additional required commands.
        if [ $vcs ] && [ -z "$(command -v git)" ]; then
            echoerr "The git command is required for VCS detection"
            return 1
        fi

        # Creates a tar.gz of the VCS or directory with the configuration

        echodebug "[DEBUG] Creating file for upload"

        echodebug "[DEBUG] Entering dir $config_dir"
        if ! cd "$config_dir"; then
            echoerr "Unable to change to configuration directory $config_dir"
            return 1
        fi

        if [ $vcs ]; then
            # VCS detection was requested so it must actually be present
            if ! git status >/dev/null 2>&1; then
                echoerr "VCS not present in $config_dir"
                echoerr "Disable VCS detection with -vcs false"
                return 1
            fi
            echodebug "[DEBUG] tar: Uploading vcs tracked files"
            echodebug "[DEBUG] excluding any plugins"
        else
            echodebug "[DEBUG] tar: Uploading all of $PWD"
            echodebug "[DEBUG] excluding VCS files and any plugins"
        fi

        # If there are modules we might want to upload them.
        has_modules="$([ -d .terraform/modules ] && echo 1 || echo )"
        echodebug "[DEBUG] Has .terraform/modules: $has_modules"

        $tarcmd "$config_payload"
        if [ $? != 0 ]; then
            echoerr "Error creating config archive payload"
            return 1
        fi

        echo "Uploading Terraform config..."

        echodebug "[DEBUG] Creating a new config version for $ws"

        # The JSON Payload used to create the new configuration version
        config_ver_payload='{"data":{"type":"configuration-versions","attributes":{"auto-queue-runs":false}}}'

        echodebug "[DEBUG] Creating config version in workspace $workspace_id"

        # Creates the configuration version and extractes the upload-url
        url=$address/api/v2/workspaces/$workspace_id/configuration-versions

        echodebug "[DEBUG] URL: $url"

        echodebug "[DEBUG] API request for config upload:"
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
        echodebug "[DEBUG] Config ID: $config_id"

        # Perform the upload of the config archive to the upload URL
        if ! (
            set -e
            url="$(printf "%s" "$upload_url_resp" | jq -r '.data.attributes."upload-url"')"
            echodebug "[DEBUG] Upload URL: $url"
            echodebug "[DEBUG] Uploading content to upload URL"

            upload_config_resp="$(curl -f $tfh_curl_silent -X PUT --data-binary "@$config_payload" ${url})"

            echodebug "[DEBUG] Upload config response:"
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
        echodebug "[DEBUG] Config status: $config_status"
        retries=$(( $retries + 1 ))
    done

    if [ "$config_status" != "uploaded" ]; then
        echoerr "Error creating run. Config status is $config_status after $retries tries"
        return 1
    fi

    make_run_payload "$destroy" "$message" "$config_id" "$workspace_id"
    echodebug "[DEBUG] Run payload contents:"
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
    echodebug "[DEBUG] Run create response:"
    echodebug "$run_create_resp"

    run_id="$(printf "%s" "$run_create_resp" | jq -r '.data.id')"

    cleanup "$run_payload"

    echodebug "[DEBUG] Run ID: $run_id"

    if [ -z "$run_id" ]; then
        echoerr "Error obtaining run ID"
        return 1
    fi

    printf "Run $run_id submitted to $org/$ws"
    if [ -n "$config_id" ]; then
        printf " using config $config_id"
    fi
    printf "\n"

    if [ 0 -eq "$poll_run" ]; then
        return 0
    fi

    # Repeatedly poll the system every N seconds specified with -poll to get
    # the run status until it reaches a non-active status. By default -poll is
    # 0 and there is no polling.
    if ! (
        set -e
        run_status=pending
        lock_id=

        # Go until we don't see one of these states
        while [ pending = "$run_status"   ] ||
              [ planning = "$run_status"  ] ||
              [ applying = "$run_status"  ] ||
              [ confirmed = "$run_status" ]; do
            # if the workspace was determined to be locked in the previous
            # poll, don't delay getting the final status and exiting.
            if [ true != "$workspace_locked" ]; then
                sleep $poll_run
            fi

            echodebug "[DEBUG] API request to poll run:"
            url=$address/api/v2/workspaces/$workspace_id/runs
            poll_run_resp="$(tfh_api_call $url)"

            run_status="$(printf "%s" "$poll_run_resp" | jq -r '.data[] | select(.id == "'$run_id'") | .attributes.status')"
            [ 0 -ne $? ] && continue

            echo "$run_status"

            echodebug "[DEBUG] API Request for workspace info $org/$ws"
            url="$address/api/v2/organizations/$org/workspaces/$ws"
            workspace_info_resp="$(tfh_api_call "$url")"

            workspace_locked="$(printf "%s" "$workspace_info_resp" | jq -r '.data.attributes.locked')"

            if [ true = "$workspace_locked" ]; then
                lock_id="$(printf "%s" "$workspace_info_resp" | jq -r '.data.relationships."locked-by".data.id')"
                if [ "$lock_id" != "$run_id" ]; then
                    echo "locked by $lock_id"
                    return 0
                fi
            fi
        done
    ) 2>&3; then
        echoerr "Error polling run"
        return 1
    fi
)
