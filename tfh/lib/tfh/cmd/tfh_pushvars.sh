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

make_var_create_payload () {
cat > "$payload" <<EOF
{
"data": {
  "type":"vars",
  "attributes": {
    "key":"$1",
    "value":"$2",
    "category":"$3",
    "hcl":$4,
    "sensitive":$5
  }
},
"filter": {
  "organization": {
    "name":"$org"
  },
  "workspace": {
    "name":"$ws"
  }
}
}
EOF
}

make_var_update_payload () {
cat > "$payload" <<EOF
{
"data": {
  "id":"$1",
  "attributes": {
    "key":"$2",
    "value":"$3",
    "category":"$4",
    "hcl":$5,
    "sensitive":$6
  },
  "type":"vars"
}
}
EOF
}

# Given a list of variables followed by the properties all of those variables
# should have, either create or update them in TFE.
# $1 variables list
# $2 variables type (terraform or env)
# $3 hcl true or false, or delete if processing a delete list
# $4 sensitive true or false, or empty if processing a delete list
process_vars () {
  # Bail out if the list is empty
  if [ -z "$1" ]; then
    return
  fi

  # Loop through the given variables. See if they are already in the
  # workspace. If so create them, else update them if they should be
  # updated.
  IFS=$JUNONIA_US
  for var in $1; do
    unset IFS
    v="${var%%=*}"
    val="${var#*=}"

    if [ "$3" = true ]; then
      val="$(escape_value "$val")"
    fi

    echodebug "$(printf "Processing %s type:%s hcl:%s sensitive:%s value:%s\n" "$v" "$2" "$3" "$4" "$val")"

    # Don't bother creating or updating if it's just going to be
    # deleted later.
    if [ "$3" != "delete" ]; then
      if [ "$2" = "terraform" ]; then
        if echo "$deletes" | grep -E "$JUNONIA_UFS$v$JUNONIA_UFS" >/dev/null 2>&1; then
          echodebug "skipping $v due to later delete"
          continue
        fi
      else
        if echo "$env_deletes" | grep -E "$JUNONIA_UFS$v$JUNONIA_UFS" >/dev/null 2>&1; then
          echodebug "skipping $v due to later delete"
          continue
        fi
      fi
    fi

    var_id="$(printf "%s" "$var_get_resp" | \
           jq -r --arg var "$v" --arg type "$2" '.data[]
      | select(.attributes.category == $type)
      | select(.attributes.key == $var)
      | .id')"
    if [ -z "$var_id" ]; then
      echodebug "$v not in variable listing"

      if [ "$3" = "delete" ]; then
        echoerr "Variable $v specified for deletion but doesn't exist"
        continue
      fi

      if [ $hide_sensitive ] && [ "$4" = true ]; then
        output_val=REDACTED
      else
        output_val="$val"
      fi

      printf "Creating %s type:%s hcl:%s sensitive:%s value:%s\n" "$v" "$2" "$3" "$4" "$output_val"

      if [ ! $dry_run ]; then
        url="$address/api/v2/vars"
        if ! make_var_create_payload "$v" "$val" $2 "$3" "$4"; then
          echoerr "Error generating payload file for $v"
          continue
        fi

        echodebug "API request for variable create:"
        if ! var_create_resp="$(tfh_api_call -d @"$payload" "$url")"; then
          echoerr "error creating variable $v"
        fi

        cleanup "$payload"
      fi
    else
      if [ "$3" = delete ]; then
        h="$(printf "%s" "$var_get_resp" | \
               jq -r --arg var "$v" --arg type "$2" '.data[]
          | select(.attributes.category == $type)
          | select(.attributes.key == $var)
          | .attributes.hcl')"

        s="$(printf "%s" "$var_get_resp" | \
               jq -r --arg var "$v" --arg type "$2" '.data[]
          | select(.attributes.category == $type)
          | select(.attributes.key == $var)
          | .attributes.sensitive')"

        o="$(printf "%s" "$var_get_resp" | \
               jq -r --arg var "$v" --arg type "$2" '.data[]
          | select(.attributes.category == $type)
          | select(.attributes.key == $var)
          | .attributes.value')"

        printf "Deleting %s type:%s hcl:%s sensitive:%s value:%s\n" "$v" "$2" "$h" "$s" "$o"

        if [ ! $dry_run ]; then
          url="$address/api/v2/vars/$var_id"
          if ! tfh_api_call --request DELETE "$url"; then
            echoerr "Error deleting variable $v"
          fi
        fi
      else
        # This existing variable should only be overwritten if it was
        # specified in the correct overwrite list or if -overwrite-all
        # is true.
        if [ $overwrite_all ] ||
           ( [ "$2" = terraform ] && echo "$overwrites" | grep -Eq "$JUNONIA_UFS$v$JUNONIA_UFS" ) ||
           ( [ "$2" = env ] && echo "$envvar_overwrites" | grep -Eq "$JUNONIA_UFS$v$JUNONIA_UFS" ); then

          if [ $hide_sensitive ] && [ "$4" = true ]; then
            output_val=REDACTED
          else
            output_val="$val"
          fi

          printf "Updating %s type:%s hcl:%s sensitive:%s value:%s\n" "$v" "$2" "$3" "$4" "$output_val"

          if [ ! $dry_run ]; then
            url="$address/api/v2/vars/$var_id"
            if ! make_var_update_payload "$var_id" "$v" "$val" "$2" "$3" "$4"; then
              echoerr "Error generating payload file for $v"
              continue
            fi

            echodebug "API request for variable update:"
            if ! var_update_resp="$(tfh_api_call --request PATCH -d @"$payload" "$url")"; then
              echoerr "Error updating variable $v"
            fi

            cleanup "$payload"
          fi
        fi
      fi
    fi
    IFS=$JUNONIA_US
  done
  unset IFS
}

tfh_pushvars () {
  config_dir="$1"
  shift
  dry_run="$1"
  shift
  vars="$1"
  shift
  svars="$1"
  shift
  hclvars="$1"
  shift
  shclvars="$1"
  shift
  envvars="$1"
  shift
  senvvars="$1"
  shift
  deletes="$1"
  shift
  env_deletes="$1"
  shift
  overwrites="$1"
  shift
  envvar_overwrites="$1"
  shift
  overwrite_all="$1"
  shift
  var_file="$1"
  shift
  hide_sensitive="$1"

  defaultvars=
  defaultvars_values=
  defaulthclvars=
  defaulthclvars_values=
  var_file_arg=

  if [ -n "$var_file" ]; then
    var_file_arg="$1"
  fi

  payload="$TMPDIR/tfe-push-vars-payload-$(junonia_randomish_int)"

  # Check for required standard options
  if ! check_required; then
    return 1
  fi

  if [ $overwrite_all ] && [ ! $dry_run ] &&
     ! echo "$TFH_CMDLINE" | grep -Eq -- '-dry-run (0|false)'; then
    echoerr "Option -overwrite-all requires -dry-run to be explicitly"
    echoerr "specified as false. Running with -dry-run true to preview operations."
    overwrite_all=1
    dry_run=1
  fi

  if [ -n "$config_dir" ] || [ -n "$var_file" ]; then
    tf_version_required 0 11 6
  fi

  # Get the variable listing for the workspace
  url="$address/api/v2/vars?filter%5Borganization%5D%5Bname%5D=$org&filter%5Bworkspace%5D%5Bname%5D=$ws"

  echodebug "API list variables URL:"
  echodebug "$url"

  echodebug "API request for variable list:"
  if ! var_get_resp="$(tfh_api_call $url)"; then
    echoerr "error listing variables"
    return 1
  fi

  # If a config directory was given, then variables with defaults in
  # the configuration need to be discovered.
  if [ -n "$config_dir" ]; then
    cd "$config_dir"
    if [ 0 -ne $? ]; then
      echoerr "Error entering the config directory:"
      echoerr "$config_dir"
      return 1
    fi

    # Get all of the variables from all of the .tf files
    # Outputs:
    #   TYPE NAME
    # e.g.
    #   hcl my_var
    all_vars="$(awk '
      BEGIN {
        in_var = 0
        in_value = 0
        in_default = 0
        in_comment = 0
        in_heredoc = 0
        heredoc_id = ""
        in_map = 0
        in_default_block = 0
        seen_variable = 0
      }
      /^[ \t\r\n\v\f]*#/ {
        # line starts with a comment
        next
      }
      /\/\*/ {
        # entering a comment block
        in_comment = 1
      }
      in_comment == 1 && /\*\// {
        # exiting a comment block
        in_comment = 0
        next
      }
      in_comment == 1 {
        # still in a comment block
        next
      }
      in_map == 1 && $0 !~ /}/ {
        # in a map and do not see a "}" to close it
        next
      }
      in_map == 1 && /}/ {
        # in a map and see a "}" to close it.
        # assuming that a variable identifier is not going to follow
        # the "}" on the same line, which could be a bad assumption
        # but also really awful formatting
        in_map = 0
        next
      }
      /variable/ && seen_variable == 0 {
        # the variable keyword
        seen_variable = 1
      }

      $0 ~ /"[-_a-zA-Z0-9]*"/ && seen_variable == 1 {
        # get the variable name
        in_var = 1
        match($0, /"[a-zA-Z0-9]/)
        l=RLENGTH
        match($0, /[-_a-zA-Z0-9]*"/)
        name = substr($0, RSTART+1, RLENGTH-l)
        seen_variable = 0
      }
      in_heredoc == 1 && $0 !~ "^" heredoc_id "$" {
        # in a heredoc and have not seen the id to end it
        next
      }
      in_heredoc == 1 && $0 ~ "^" heredoc_id "$" {
        # exiting a heredoc
        in_heredoc = 0
        heredoc_id = ""
        next
      }
      in_var == 1 && /{/ {
        # entered the variable block to look for default
        in_var_block = 1
      }
      in_var_block == 1 && /default/ {
        # this variable has a default
        in_default = 1
      }
      in_var_block == 1 && in_default == 0 && in_value == 0 && /}/ {
        # Variable block with no default. Its value may come from
        # a tfvars file loaded later.
        in_var = 0
        in_var_block = 0
        in_default = 0
        in_default_block = 0
        in_value = 0
        next
      }
      in_default == 1 && /=/{
        # entering the RHS of default =
        in_value = 1

        # strip everything up to = and whitespace to make
        # detection of unquoted true/false easier when = and
        # true/false are on the same line.
        sub(/[^=]*[ \t\r\n\v\f]*=[ \t\r\n\v\f]*/, "")
      }
      in_var == 1 && in_default == 1 && in_value == 1 && /["{<\[tf]/ {
        # inside the RHS and found something that looks like a value.
        # determine the variable type (hcl, non-hcl).
        # match all the things that are not Terraform variable values
        m = match($0, /[^"{<\[tf]*/)
        if(m != 0) {
          # Get the first character after all of the things that are not
          # Terraform variable values
          value_char = substr($0, RLENGTH + 1, 1)

          if(value_char == "{") {
            # this is a map. if it is not all on one line then
            # we are in a map
            if(match($0, /}/) == 0){
              in_map = 1
            }
          }
          if(value_char == "<") {
            # entering a heredoc. valid anchors should be directly
            # next to the brackets
            in_heredoc = 1
            match($0, /<<[-_a-zA-Z0-9]+/)
            heredoc_id = substr($0, RSTART+2, RLENGTH-2)
          }
          if(value_char == "t") {
            # Check to ensure the value is unquoted true
            true_chars = substr($0, RLENGTH + 1, 4)
            if(true_chars != "true") {
              # If not then start the search over
              in_var = 0
              in_value = 0
              in_var_block = 0
              in_default = 0
              in_default_block = 0
              next
            }
          }
          if(value_char == "f") {
            # Check to ensure the value is false
            false_chars = substr($0, RLENGTH + 1, 5)
            if(false_chars != "false") {
              # If not then start the search over
              in_var = 0
              in_value = 0
              in_var_block = 0
              in_default = 0
              in_default_block = 0
              next
            }
          }

          # not in a map, so this is a variable name
          print name
          in_var = 0
          in_value = 0
          in_var_block = 0
          in_default = 0
          in_default_block = 0
        }
      } ' *.tf)"
  elif [ -n "$var_file" ]; then
    # Going to locate all of the variables from a tfvars file.
    # Will get the values by using the tfvars file and creating a
    # temporary config with just variable names in it for use with
    # the terraform console command.
    tfvar_dir="$TMPDIR/tfe-push-vars-$(random_enough)"
    if ! mkdir "$tfvar_dir"; then
      echoerr "error creating temporary directory for tfvars."
      return 1
    fi

    echodebug "Temporary tfvars dir:"
    echodebug "$tfvar_dir"

    if ! cp "$var_file" "$tfvar_dir"; then
      echoerr "Error copying variable file to temporary path."
      return 1
    fi

    if ! cd "$tfvar_dir"; then
      echoerr "Error entering variable file temporary path."
      return 1
    fi

    # This is not a great "parser" but it hopefully overreaches on finding
    # variable names, then we can silently ignore errors from terraform
    # console (output when TF_LOG=1).

    # Outputs:
    #   TYPE NAME
    # e.g.
    #   hcl my_var
    all_vars="$(awk '
      BEGIN {
        in_var = 0
        in_value = 0
        in_comment = 0
        in_heredoc = 0
        heredoc_id = ""
        in_map = 0
      }
      /^[ \t\r\n\v\f]*#/ {
        # line starts with a comment
        next
      }
      /\/\*/ {
        # entering a comment block
        in_comment = 1
        next
      }
      in_comment == 1 && /\*\// {
        # exiting a comment block
        in_comment = 0
        next
      }
      in_comment == 1 {
        # still in a comment block
        next
      }
      in_map == 1 && $0 !~ /}/ {
        # in a map and do not see a "}" to close it
        next
      }
      in_map == 1 && /}/ {
        # in a map and see a "}" to close it.
        # assuming that a variable identifier is not going to follow
        # the "}" on the same line, which could be a bad assumption
        # but also really awful formatting
        in_map = 0
        next
      }
      in_heredoc == 1 && $0 !~ "^" heredoc_id "$" {
        # in a heredoc and have not seen the id to end it
        next
      }
      in_heredoc == 1 && $0 ~ "^" heredoc_id "$" {
        # exiting a heredoc
        in_heredoc = 0
        heredoc_id = ""
        next
      }
      /^[ \t\r\n\v\f]*[a-zA-Z0-9]/ && in_var == 0 && $0 !~ /,$/ {
        # token text, not in a variable already, does not end in ",".
        # this looks like a variable name
        in_var = 1
        match($0, /[-_a-zA-Z0-9]+/)
        name = substr($0, RSTART, RLENGTH)

        # remove the potential variable name from $0 so a search
        # for "=" can continue on this line as well as subsequent lines
        sub(name, "")

        # remove whitespace so that the next character either is or is
        # not "="
        sub(/^[ \t\r\n\v\f]+/, "")
      }
      in_var == 1 && /^[^=]/ {
        # have a potential variable name but the next thing seen
        # is not "=", so this is not a variable name.
        in_var = 0
        next
      }
      in_var == 1 && /^=/ {
        # have a variable name and the next thing seen is =
        in_value = 1

        # strip everything up to = and whitespace to make
        # detection of unquoted true/false easier when = and
        # true/false are on the same line.
        sub(/[^=]*[ \t\r\n\v\f]*=[ \t\r\n\v\f]*/, "")
      }
      in_var == 1 && in_value == 1 && /["{<\[tf]/ {
        # see if we are entering a map or heredoc so we can skip those
        # sections.
        # match all the things that are not Terraform variable values.
        m = match($0, /[^"{<\[tf]*/)
        if(m != 0) {
          # Get the first character after all of the things that are not
          # Terraform variable values
          value_char = substr($0, RLENGTH + 1, 1)

          if(value_char == "{") {
            # this is a map. if it is not all on one line then
            # we are in a map
            if(match($0, /}/) == 0){
              in_map = 1
            }
          }
          if(value_char == "<") {
            # entering a heredoc. valid anchors should be directly
            # next to the brackets
            in_heredoc = 1
            match($0, /<<[-_a-zA-Z0-9]+/)
            heredoc_id = substr($0, RSTART+2, RLENGTH-2)
          }
          if(value_char == "t") {
            # Check to ensure the value is unquoted true
            true_chars = substr($0, RLENGTH + 1, 4)
            if(true_chars != "true") {
              # If not then start the search over
              in_var = 0
              in_value = 0
              next
            }
          }
          if(value_char == "f") {
            # Check to ensure the value is false
            false_chars = substr($0, RLENGTH + 1, 5)
            if(false_chars != "false") {
              # If not then start the search over
              in_var = 0
              in_value = 0
              next
            }
          }

          # not in a map, so this is a variable name
          print name
          printf "variable \"%s\" {}\n", name >> "vars.tf"
          in_var = 0
          in_value = 0
        }
      }' "$(basename "$var_file")")"

      echodebug "Temporary directory contents:"
      echodebug "$(ls)"

      echodebug "Temporary file contents:"
      echodebug "$(cat *)"
  fi

  echodebug "All variables:"
  echodebug "$all_vars"

  # All of the 'parsed' variable names are just candidates, as they may
  # not have defaults or may not be variable names at all (e.g. map
  # assignments). Loop through the potential variables and get their
  # values, then determine if they are HCL or not.

  if [ -n "$all_vars" ]; then
    if [ -n "$config_dir" ] && [ ! -d .terraform ]; then
      echoerr "WARNING: Terraform configuration appears uninitialized!"
      echoerr "When specifying a config directory run terraform init."
      echoerr "Variables may be skipped or passed unintended values."
    fi

    for var in $all_vars; do
      if [ -z "$var_file_arg" ]; then
        val_lines="$(echo "var.$var" | terraform console 2>&3)"
      else
        val_lines="$(echo "var.$var" | terraform console "$var_file_arg" 2>&3)"
      fi

      if [ 0 -ne $? ]; then
        echodebug "Unable to retrieve value for potential variable $var"
        echodebug "Stdout of terraform console was:"
        echodebug "$val_lines"
        continue
      fi
      val="$(escape_value "$val_lines")"

      # Inspect the first character of the value to see if it is a
      # list or map
      first="$(echo "$val" | cut -c 1-1 | head -1)"
      if [ "$first" = "{" ] || [ "$first" = "[" ]; then
        defaulthclvars="$defaulthclvars$JUNONIA_UFS$var=$val"
      else
        defaultvars="$defaultvars$JUNONIA_UFS$var=$val"
      fi
    done
  fi

  # Send each list of the different types of variables through to be created
  # or updated, along with the properties that that list should abide by.

  #            variable list     type      hcl   sensitive
  process_vars "$defaultvars"    terraform false false
  process_vars "$defaulthclvars" terraform true  false
  process_vars "$vars"           terraform false false
  process_vars "$hclvars"        terraform true  false
  process_vars "$svars"          terraform false true
  process_vars "$shclvars"       terraform true  true
  process_vars "$envvars"        env       false false
  process_vars "$senvvars"       env       false true
  process_vars "$deletes"        terraform delete
  process_vars "$env_deletes"    env       delete
}
