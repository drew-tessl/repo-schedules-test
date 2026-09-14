#!/usr/bin/env bash

credential_name=${1:-}
[[ $credential_name =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || exit 0
[[ $credential_name == "LINEAR_TOKEN" || $credential_name == *_LINEAR_TOKEN ]] || exit 0

credential_value=${!credential_name-}
[[ -n $credential_value ]] || exit 0

header_file=$(mktemp) || exit 0
response_file=$(mktemp) || {
  rm -f "$header_file"
  exit 0
}
trap 'rm -f "$header_file" "$response_file"' EXIT
printf 'Authorization: %s\n' "$credential_value" >"$header_file" || exit 0

status=$(
  curl --silent --show-error --connect-timeout 5 --max-time 10 \
    --request POST \
    --header "@$header_file" \
    --header "Content-Type: application/json" \
    --data '{"query":"{ viewer { id } }"}' \
    --output "$response_file" \
    --write-out '%{http_code}' \
    https://api.linear.app/graphql 2>/dev/null
) || exit 0

# Reject only 401. A 403 means the credential authenticated but lacks access to
# this path, so rejecting it would stop runs with valid scope-limited tokens.
[[ $status == "401" ]] && exit 1
exit 0
