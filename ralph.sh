#!/usr/bin/env bash
set -euo pipefail

MODEL_ID="gpt-5.2-codex"
REASONING_EFFORT="medium"
MAX_ITERS=""
ITERS_SET="false"

usage() {
  echo 'Usage: ./ralph.sh -n <iters> [-m <model>] [-r <reasoning>]'
  echo 'Required: -n'
}

while getopts ":n:m:r:h" opt; do
  case "$opt" in
    n) MAX_ITERS="$OPTARG"; ITERS_SET="true" ;;
    m) MODEL_ID="$OPTARG" ;;
    r) REASONING_EFFORT="$OPTARG" ;;
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

echo "Ralph [model=${MODEL_ID} reason=${REASONING_EFFORT} iters=${MAX_ITERS}]"

for ((i=1;i<=MAX_ITERS;i++)); do
  echo "== Iter $i/$MAX_ITERS =="
  read -r -d '' PROMPT <<EOF || true
Ralph iter $i. Reason(label): ${REASONING_EFFORT}
TASK: ${USER_PROMPT}
EOF
  codex exec --model "${MODEL_ID}" --output-last-message "codex_last_message_iter_${i}.txt" "$PROMPT"
  sleep 2
done

echo "Ralph finished"
