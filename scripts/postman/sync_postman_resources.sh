#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
POSTMAN_DIR="${ROOT_DIR}/postman"
COLLECTION_FILE="${POSTMAN_DIR}/collections/climbing_fantasy_api.postman_collection.json"
LOCAL_ENV_FILE="${POSTMAN_DIR}/environments/climbing_fantasy_local.postman_environment.json"
MOCK_ENV_FILE="${POSTMAN_DIR}/environments/climbing_fantasy_mock.postman_environment.json"
STATE_FILE="${POSTMAN_DIR}/postman_resources.json"

POSTMAN_API_BASE="https://api.getpostman.com"
WORKSPACE_NAME="${POSTMAN_WORKSPACE_NAME:-Team Workspace}"
MOCK_NAME="${POSTMAN_MOCK_NAME:-Climbing Fantasy API Mock}"

if [[ -z "${POSTMAN_API_KEY:-}" ]]; then
  echo "POSTMAN_API_KEY is required."
  echo "Example: export POSTMAN_API_KEY='PMAK-...'"
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required."
  exit 1
fi

request() {
  local method="$1"
  local path="$2"
  local data_file="${3:-}"
  if [[ -n "${data_file}" ]]; then
    curl -sS -X "${method}" "${POSTMAN_API_BASE}${path}" \
      -H "X-Api-Key: ${POSTMAN_API_KEY}" \
      -H "Content-Type: application/json" \
      --data "@${data_file}"
  else
    curl -sS -X "${method}" "${POSTMAN_API_BASE}${path}" \
      -H "X-Api-Key: ${POSTMAN_API_KEY}"
  fi
}

to_payload_file() {
  local input_file="$1"
  local wrapper_key="$2"
  local output_file="$3"
  jq --arg wrapper_key "${wrapper_key}" '{($wrapper_key): .}' "${input_file}" > "${output_file}"
}

echo "Building fixture-backed Postman assets..."
ruby "${ROOT_DIR}/scripts/postman/build_postman_assets.rb"

workspace_id="$(request GET "/workspaces" | jq -r --arg name "${WORKSPACE_NAME}" '.workspaces[] | select(.name == $name) | .id' | head -n1)"
if [[ -z "${workspace_id}" ]]; then
  echo "Workspace not found: ${WORKSPACE_NAME}"
  exit 1
fi

echo "Using workspace: ${WORKSPACE_NAME} (${workspace_id})"

state_json='{}'
if [[ -f "${STATE_FILE}" ]]; then
  state_json="$(cat "${STATE_FILE}")"
fi

collection_name="$(jq -r '.info.name' "${COLLECTION_FILE}")"
local_env_name="$(jq -r '.name' "${LOCAL_ENV_FILE}")"
mock_env_name="$(jq -r '.name' "${MOCK_ENV_FILE}")"

all_collections="$(request GET "/collections")"
all_environments="$(request GET "/environments")"

collection_uid_from_state="$(jq -r '.collection_uid // ""' <<<"${state_json}")"
if [[ -n "${collection_uid_from_state}" ]]; then
  collection_uid="${collection_uid_from_state}"
else
  collection_uid="$(jq -r --arg name "${collection_name}" '.collections[]? | select(.name == $name) | .uid' <<<"${all_collections}" | head -n1)"
fi

local_env_uid_from_state="$(jq -r '.local_environment_uid // ""' <<<"${state_json}")"
if [[ -n "${local_env_uid_from_state}" ]]; then
  local_env_uid="${local_env_uid_from_state}"
else
  local_env_uid="$(jq -r --arg name "${local_env_name}" '.environments[]? | select(.name == $name) | .uid' <<<"${all_environments}" | head -n1)"
fi

mock_env_uid_from_state="$(jq -r '.mock_environment_uid // ""' <<<"${state_json}")"
if [[ -n "${mock_env_uid_from_state}" ]]; then
  mock_env_uid="${mock_env_uid_from_state}"
else
  mock_env_uid="$(jq -r --arg name "${mock_env_name}" '.environments[]? | select(.name == $name) | .uid' <<<"${all_environments}" | head -n1)"
fi

tmp_collection_payload="$(mktemp)"
tmp_local_env_payload="$(mktemp)"
tmp_mock_env_payload="$(mktemp)"
tmp_mock_payload="$(mktemp)"
tmp_mock_env_raw="${tmp_mock_env_payload}.raw"
tmp_mock_env_raw2="${tmp_mock_env_payload}.raw2"

trap 'rm -f "${tmp_collection_payload}" "${tmp_local_env_payload}" "${tmp_mock_env_payload}" "${tmp_mock_payload}" "${tmp_mock_env_raw}" "${tmp_mock_env_raw2}"' EXIT

to_payload_file "${COLLECTION_FILE}" "collection" "${tmp_collection_payload}"
to_payload_file "${LOCAL_ENV_FILE}" "environment" "${tmp_local_env_payload}"

if [[ -n "${collection_uid}" ]]; then
  echo "Updating collection: ${collection_name} (${collection_uid})"
  request PUT "/collections/${collection_uid}" "${tmp_collection_payload}" >/dev/null
else
  echo "Creating collection: ${collection_name}"
  collection_uid="$(request POST "/collections?workspace=${workspace_id}" "${tmp_collection_payload}" | jq -r '.collection.uid')"
fi

if [[ -n "${local_env_uid}" ]]; then
  echo "Updating environment: ${local_env_name} (${local_env_uid})"
  request PUT "/environments/${local_env_uid}" "${tmp_local_env_payload}" >/dev/null
else
  echo "Creating environment: ${local_env_name}"
  local_env_uid="$(request POST "/environments?workspace=${workspace_id}" "${tmp_local_env_payload}" | jq -r '.environment.uid')"
fi

mock_url_from_state="$(jq -r '.mock_url // ""' <<<"${state_json}")"
mock_url="${mock_url_from_state:-https://replace-me.mock.pstmn.io}"

jq --arg url "${mock_url}" '
  .values |= map(if .key == "baseUrl" then .value = $url else . end)
' "${MOCK_ENV_FILE}" > "${tmp_mock_env_raw}"
to_payload_file "${tmp_mock_env_raw}" "environment" "${tmp_mock_env_payload}"

if [[ -n "${mock_env_uid}" ]]; then
  echo "Updating environment: ${mock_env_name} (${mock_env_uid})"
  request PUT "/environments/${mock_env_uid}" "${tmp_mock_env_payload}" >/dev/null
else
  echo "Creating environment: ${mock_env_name}"
  mock_env_uid="$(request POST "/environments?workspace=${workspace_id}" "${tmp_mock_env_payload}" | jq -r '.environment.uid')"
fi

mock_id_from_state="$(jq -r '.mock_id // ""' <<<"${state_json}")"

jq -n \
  --arg name "${MOCK_NAME}" \
  --arg collection "${collection_uid}" \
  --arg environment "${mock_env_uid}" \
  '{mock: {name: $name, collection: $collection, environment: $environment}}' > "${tmp_mock_payload}"

if [[ -n "${mock_id_from_state}" ]]; then
  echo "Updating mock: ${MOCK_NAME} (${mock_id_from_state})"
  mock_response="$(request PUT "/mocks/${mock_id_from_state}" "${tmp_mock_payload}")"
else
  echo "Creating mock: ${MOCK_NAME}"
  mock_response="$(request POST "/mocks?workspace=${workspace_id}" "${tmp_mock_payload}")"
fi

mock_id="$(jq -r '.mock.id // empty' <<<"${mock_response}")"
mock_uid="$(jq -r '.mock.uid // empty' <<<"${mock_response}")"
mock_url="$(jq -r '.mock.mockUrl // empty' <<<"${mock_response}")"

if [[ -z "${mock_id}" || -z "${mock_url}" ]]; then
  echo "Failed to create/update mock."
  echo "${mock_response}" | jq .
  exit 1
fi

jq --arg url "${mock_url}" '
  .values |= map(if .key == "baseUrl" then .value = $url else . end)
' "${MOCK_ENV_FILE}" > "${tmp_mock_env_raw2}"
to_payload_file "${tmp_mock_env_raw2}" "environment" "${tmp_mock_env_payload}"
request PUT "/environments/${mock_env_uid}" "${tmp_mock_env_payload}" >/dev/null

jq -n \
  --arg workspace_name "${WORKSPACE_NAME}" \
  --arg workspace_id "${workspace_id}" \
  --arg collection_uid "${collection_uid}" \
  --arg local_environment_uid "${local_env_uid}" \
  --arg mock_environment_uid "${mock_env_uid}" \
  --arg mock_id "${mock_id}" \
  --arg mock_uid "${mock_uid}" \
  --arg mock_url "${mock_url}" \
  '{
    workspace_name: $workspace_name,
    workspace_id: $workspace_id,
    collection_uid: $collection_uid,
    local_environment_uid: $local_environment_uid,
    mock_environment_uid: $mock_environment_uid,
    mock_id: $mock_id,
    mock_uid: $mock_uid,
    mock_url: $mock_url
  }' > "${STATE_FILE}"

echo "Sync complete."
echo "Collection UID: ${collection_uid}"
echo "Local Environment UID: ${local_env_uid}"
echo "Mock Environment UID: ${mock_env_uid}"
echo "Mock URL: ${mock_url}"
