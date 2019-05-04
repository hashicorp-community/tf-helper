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

tfh_pullvars () (
  vars="$1"
  env_vars="$2"
  env="$3"
  
  # Check for required standard options
  if ! check_required; then
    return 1
  fi

  # Handle conflicting options
  if [ $env ] && ( [ -n "$vars" ] || [ -n "$env_vars" ] ); then
    echoerr "-env true cannot be specified along with -var and/or -env-var"
    return 1
  fi

  # request template
  url="$address/api/v2/vars?filter%5Borganization%5D%5Bname%5D=$org&filter%5Bworkspace%5D%5Bname%5D=$ws"

  echodebug "API list variables URL:"
  echodebug "$url"

  # API call to get all of the variables
  echodebug "API request for variable list:"
  if ! var_get_resp="$(tfh_api_call $url)"; then
    echoerr "Error listing variables"
    return 1
  fi

  vars_retval=0
  tfevar=

  if [ -n "$vars" ]; then
    # Removoe the end-of-list marker added by append when using vars
    for v in ${vars%.}; do
      # Get this tf var out of the variable list with jq
      tfevar="$(printf "%s" "$var_get_resp" | jq -r --arg var "$v" '.data[]
        | select(.attributes.category == "terraform")
        | select(.attributes.key == $var)
        | [
          .attributes.key + " = ",
          (if .attributes.hcl == false or .attributes.sensitive == true then "\"" else empty end),
          .attributes.value,
          (if .attributes.hcl == false or .attributes.sensitive == true then "\"" else empty end)
          ]
        | join("")')"

      if [ -z "$tfevar" ]; then
        echoerr "Variable $v not found"
        vars_retval=1
      else
        echo "$tfevar"
      fi
    done
  fi

  if [ -n "$env_vars" ]; then
    # Removoe the end-of-list marker added by append when using env_vars
    for v in ${env_vars%.}; do
      # Get this env var out of the variable list with jq
      tfevar="$(printf "%s" "$var_get_resp" | jq -r --arg var "$v" '.data[]
        | select(.attributes.category == "env")
        | select(.attributes.key == $var)
        | .attributes.key + "=\"" + .attributes.value + "\""')"

      if [ -z "$tfevar" ]; then
        echoerr "Variable $v not found"
        vars_retval=1
      else
        echo "$tfevar"
      fi
    done
  fi

  if [ -n "$vars" ] || [ -n "$env_vars" ]; then
    return $vars_retval
  fi

  # Didn't retrieve a specific list of vars so
  # either list all tf or all env vars
  terraform_tfvars="$(printf "%s" "$var_get_resp" | jq -r '.data[]
    | select(.attributes.category == "terraform")
    | select(.attributes.sensitive == false)
    | [
      .attributes.key + " = ",
      (if .attributes.hcl == false then
        if .attributes.value | contains("\n") then
          "<<EOF\n"
        else
          "\""
        end
      else empty end),
      .attributes.value,
      (if .attributes.hcl == false then
        if .attributes.value | contains("\n") then
          "\nEOF"
        else
          "\""
        end
      else empty end),
      "\n"
      ]
    | join("")')"
  if [ 0 -ne $? ]; then
    echoerr "Error parsing API response for Terraform variables"
    return 1
  fi

  sensitive_tfvars="$(printf "%s" "$var_get_resp" | jq -r '.data[]
    | select(.attributes.category == "terraform")
    | select(.attributes.sensitive == true)
    | .attributes.key + " = \"\""')"
  if [ 0 -ne $? ]; then
    echoerr "Error parsing API response for sensitive Terraform variables"
    return 1
  fi

  env_vars="$(printf "%s" "$var_get_resp" | jq -r '.data[]
    | select(.attributes.category == "env")
    | select(.attributes.sensitive == false)
    | .attributes.key + "=\"" + .attributes.value + "\""')"
  if [ 0 -ne $? ]; then
    echoerr "Error parsing API response for environment variables"
    return 1
  fi

  sensitive_env_vars="$(printf "%s" "$var_get_resp" | jq -r '.data[]
    | select(.attributes.category == "env")
    | select(.attributes.sensitive == true)
    | .attributes.key + "="')"
  if [ 0 -ne $? ]; then
    echoerr "Error parsing API response for sensitive environment variables"
    return 1
  fi

  # All env vars were requested
  if [ $env ]; then
    if [ -n "$sensitive_env_vars" ]; then
      echo "$sensitive_env_vars"
    fi

    if [ -n "$env_vars" ]; then
      echo "$env_vars"
    fi

    return 0
  fi

  # All tf vars were requested
  if [ -n "$sensitive_tfvars" ]; then
    echo "$sensitive_tfvars"
  fi

  if [ -n "$terraform_tfvars" ]; then
    echo "$terraform_tfvars"
  fi
)
