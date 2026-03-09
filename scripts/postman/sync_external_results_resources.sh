#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
POSTMAN_DIR="${ROOT_DIR}/postman"
COLLECTION_FILE="${POSTMAN_DIR}/collections/external_results_apis.postman_collection.json"
ENV_FILE="${POSTMAN_DIR}/environments/external_results_apis_local.postman_environment.json"
STATE_FILE="${POSTMAN_DIR}/external_results_postman_resources.json"

if [[ -z "${POSTMAN_API_KEY:-}" && -f "${ROOT_DIR}/.env.local" ]]; then
  set -a
  source "${ROOT_DIR}/.env.local"
  set +a
fi

POSTMAN_API_BASE="https://api.getpostman.com"
WORKSPACE_NAME="${POSTMAN_WORKSPACE_NAME:-Team Workspace}"

if [[ -z "${POSTMAN_API_KEY:-}" ]]; then
  echo "POSTMAN_API_KEY is required."
  echo "Set it in .env.local or export it: export POSTMAN_API_KEY='PMAK-...'"
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required."
  exit 1
fi

if [[ ! -f "${COLLECTION_FILE}" || ! -f "${ENV_FILE}" ]]; then
  echo "External Postman assets are missing."
  echo "Expected:"
  echo "  ${COLLECTION_FILE}"
  echo "  ${ENV_FILE}"
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
env_name="$(jq -r '.name' "${ENV_FILE}")"

all_collections="$(request GET "/collections")"
all_environments="$(request GET "/environments")"

collection_uid_from_state="$(jq -r '.collection_uid // ""' <<<"${state_json}")"
if [[ -n "${collection_uid_from_state}" ]]; then
  collection_uid="${collection_uid_from_state}"
else
  collection_uid="$(jq -r --arg name "${collection_name}" '.collections[]? | select(.name == $name) | .uid' <<<"${all_collections}" | head -n1)"
fi

env_uid_from_state="$(jq -r '.environment_uid // ""' <<<"${state_json}")"
if [[ -n "${env_uid_from_state}" ]]; then
  env_uid="${env_uid_from_state}"
else
  env_uid="$(jq -r --arg name "${env_name}" '.environments[]? | select(.name == $name) | .uid' <<<"${all_environments}" | head -n1)"
fi

tmp_collection_payload="$(mktemp)"
tmp_env_payload="$(mktemp)"
trap 'rm -f "${tmp_collection_payload}" "${tmp_env_payload}"' EXIT

to_payload_file "${COLLECTION_FILE}" "collection" "${tmp_collection_payload}"
to_payload_file "${ENV_FILE}" "environment" "${tmp_env_payload}"

if [[ -n "${collection_uid}" ]]; then
  echo "Updating collection: ${collection_name} (${collection_uid})"
  request PUT "/collections/${collection_uid}" "${tmp_collection_payload}" >/dev/null
else
  echo "Creating collection: ${collection_name}"
  collection_uid="$(request POST "/collections?workspace=${workspace_id}" "${tmp_collection_payload}" | jq -r '.collection.uid')"
fi

if [[ -n "${env_uid}" ]]; then
  echo "Updating environment: ${env_name} (${env_uid})"
  request PUT "/environments/${env_uid}" "${tmp_env_payload}" >/dev/null
else
  echo "Creating environment: ${env_name}"
  env_uid="$(request POST "/environments?workspace=${workspace_id}" "${tmp_env_payload}" | jq -r '.environment.uid')"
fi

jq -n \
  --arg workspace_name "${WORKSPACE_NAME}" \
  --arg workspace_id "${workspace_id}" \
  --arg collection_uid "${collection_uid}" \
  --arg environment_uid "${env_uid}" \
  '{
    workspace_name: $workspace_name,
    workspace_id: $workspace_id,
    collection_uid: $collection_uid,
    environment_uid: $environment_uid
  }' > "${STATE_FILE}"

echo "Sync complete."
echo "Collection UID: ${collection_uid}"
echo "Environment UID: ${env_uid}"
