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

# Write a given token value to a curl config file at the given path.
# $1 file path
# $2 token
make_curlrc () {
  curlrc_dir="$(dirname "$1")"

  if [ ! -d "$curlrc_dir" ]; then
    if ! mkdir -p "$curlrc_dir"; then
      echoerr "unable to create configuration directory:"
      echoerr "$curlrc_dir"
      return 1
    fi
  fi

  if ! echo > "$1"; then
    echoerr "Error: cannot write to curl config file:"
    echoerr "$1"
    return 1
  fi

  if ! chmod 600 "$1"; then
    echoerr "WARNING: unable to set permissions on curl config file:"
    echoerr "chmod 600 $1"
  fi

  if ! echo "--header \"Authorization: Bearer $2\"" > "$1"; then
    echoerr "Error: cannot generate curl config file:"
    echoerr "$1"
    return 1
  fi

  echodebug "Created $1"
}

tfh_curl_config () {
  tfrc="$1"
  curltoken="$2"

  if [ -n "$curltoken" ] && [ -n "$tfrc" ]; then
    echoerr "only one of -curltoken or -tfrc can be specified"
    return 1
  fi

  if [ -n "$curltoken" ]; then
    # (Re)create / overwrite the curlrc
    make_curlrc "$curlrc" "$curltoken"
    echo "wrote $curlrc"
    return 0
  fi

  tf_config_token=
  tf_config="${TERRAFORM_CONFIG:-"$HOME/.terraformrc"}"
  if [ -f "$tf_config" ]; then
    # This is simplified. It depends on the token keyword and value being
    # on the same line in the .terraformrc.
    tf_config_token="$(awk -v host="$hostname" '
      # Skip commented lines
      /^ *#/ {
        next
      }

      # Get the host for this credentials entry
      /credentials  *"/ {
        cred_host = $2
        gsub(/"/, "", cred_host)
      }

      # Extract the token and note if it matches the specified host
      /token *= *"[A-Za-z0-9\.]+"/ {
        tokens++
        match($0, /"[A-Za-z0-9\.]+"/)
        token = substr($0, RSTART+1, RLENGTH-2)

        if(cred_host == host) {
          host_token = token
        }
      }

      END {
        # There was only one token, use that regardless as to the host
        if(tokens == 1) {
          print token
        }

        # More than one token, use the specified host
        if(tokens > 1 && host_token) {
          print host_token
        }

        # Either did not find any tokens or found tokens, but did not find the
        # token for the specified host. To avoid being ambiguous, do not output
        # any tokens.
      }' "$tf_config")"
  fi

  if [ $tfrc ]; then
    if [ -n "$tf_config_token" ]; then
      if ! make_curlrc "$curlrc" "$tf_config_token"; then
        echoerr "failed to create curlrc with terraformrc token"
        echoerr "source: $tf_config"
        echoerr "destination: $curlrc"
        return 1
      fi
      echo "$curlrc generated from $tf_config"
      return 0
    else
      echoerr "unable to extract token from terraformrc:"
      echoerr "$tf_config"
      return 1
    fi
  fi

  if [ -f "$curlrc" ]; then
    echo "$curlrc"
    echov "$(cat "$curlrc")"

    if [ -f "$tf_config" ] && [ -z "$TFH_NO_CURLRC_DIFF" ] ; then
      # Got a .terraformrc token and the current token is from a tfh curl
      # config. Compare the tokens to see if they're the same.
      curlrc_token="$(awk '
        /Bearer [A-Za-z0-9\.][A-Za-z0-9\.]*/ {
          match($0, /Bearer [A-Za-z0-9\.][A-Za-z0-9\.]*/)
          print substr($0, RSTART+7, RLENGTH-7)
        }' "$curlrc")"

      if [ "$curlrc_token" != "$tf_config_token" ]; then
        echo
        echo "WARNING tokens do not match in files:"
        echo "$tf_config"
        echo "$curlrc"
        echo
        echo "tfh will use: $curlrc"
        echo
        echo "to use $tf_config, run \`tfh curl-config -tfrc\`"
        echo
        echo "suppress this message by setting TFH_NO_CURLRC_DIFF=1"
        echo

        echov "curlrc     : $curlrc_token"
        echov "terraformrc: $tf_config_token"
      fi
    fi
  else
    echo "no curlrc file at $curlrc"
  fi
}
