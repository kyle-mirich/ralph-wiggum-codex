#!/usr/bin/env bash
set -euo pipefail

MAX_ITERS=""
ITERS_SET="false"
MODEL_ID=""

usage() {
  echo 'Usage: ./ralph-gemini.sh -n <iters> [-m <model>]'
  echo 'Required: -n'
}

while getopts ":n:m:h" opt; do
  case "$opt" in
    n) MAX_ITERS="$OPTARG"; ITERS_SET="true" ;;
    m) MODEL_ID="$OPTARG" ;;
    h) usage; exit 0 ;;
    \?) echo "Bad flag -$OPTARG"; usage; exit 1 ;;
    :)  echo "Missing value -$OPTARG"; usage; exit 1 ;;
  esac
done

[[ "${ITERS_SET}" != "true" || -z "${MAX_ITERS}" ]] && { echo "ERROR: -n required"; usage; exit 1; }
if ! [[ "${MAX_ITERS}" =~ ^[0-9]+$ ]] || [[ "${MAX_ITERS}" -lt 1 ]]; then
  echo "ERROR: -n must be a positive integer"
  usage
  exit 1
fi
if [[ ! -f "PROMPT.md" ]]; then
  echo "ERROR: PROMPT.md not found in repo root"
  exit 1
fi

USER_PROMPT="$(cat PROMPT.md)"
if [[ -z "${USER_PROMPT}" ]]; then
  echo "ERROR: PROMPT.md is empty"
  exit 1
fi

if [[ -n "${MODEL_ID}" ]]; then
  echo "Ralph [model=${MODEL_ID} (override) iters=${MAX_ITERS}]"
else
  echo "Ralph [iters=${MAX_ITERS}]"
fi

for ((i=1;i<=MAX_ITERS;i++)); do
  echo "== Iter $i/$MAX_ITERS =="
  read -r -d '' PROMPT <<EOF || true
Ralph iter $i.
TASK: ${USER_PROMPT}
EOF
  # Using -y (yolo) to auto-approve tools for autonomous loop.
  # Sandbox and model are now controlled by .gemini/settings.json unless -m is overridden
  if [[ -n "${MODEL_ID}" ]]; then
     gemini --model "${MODEL_ID}" -y "$PROMPT" > "gemini_last_message_iter_${i}.txt"
  else
     gemini -y "$PROMPT" > "gemini_last_message_iter_${i}.txt"
  fi
  sleep 2
done

echo "Ralph finished"
