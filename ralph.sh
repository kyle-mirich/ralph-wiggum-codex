#!/usr/bin/env bash
set -euo pipefail

MODEL_ID="gpt-5.2-codex"
REASONING_EFFORT="medium"
MAX_ITERS=""
USER_PROMPT=""

usage() {
  echo 'Usage: ./ralph.sh -p "<prompt>" -n <iters> [-m <model>] [-r <reasoning>]'
}

while getopts ":p:n:m:r:h" opt; do
  case "$opt" in
    p) USER_PROMPT="$OPTARG" ;;
    n) MAX_ITERS="$OPTARG" ;;
    m) MODEL_ID="$OPTARG" ;;
    r) REASONING_EFFORT="$OPTARG" ;;
    h) usage; exit 0 ;;
    \?) echo "Bad flag -$OPTARG"; usage; exit 1 ;;
    :)  echo "Missing value -$OPTARG"; usage; exit 1 ;;
  esac
done

[[ -z "${MAX_ITERS}" ]] && { echo "ERROR: -n required"; usage; exit 1; }
[[ -z "${USER_PROMPT}" ]] && { echo "ERROR: -p required"; usage; exit 1; }

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
