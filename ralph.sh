#!/usr/bin/env bash
set -euo pipefail

MODEL_ID="gpt-5.2-codex"
REASONING_EFFORT="medium"
MAX_ITERS=""

# Always clean up plans/ when we exit normally or via Ctrl+C
cleanup() {
  # Only delete if it exists and is a directory
  if [[ -d "plans" ]]; then
    rm -rf plans
  fi
}
trap cleanup EXIT INT TERM

usage() {
  cat <<'EOF'
Usage: ./ralph.sh -n <iterations> [-m <model>] [-r <reasoning>]

Options:
  -n   Max iterations (required)
  -m   Model id (default: gpt-5.2-codex)
  -r   Reasoning effort label (default: medium) [stored in prompt only]
  -h   Show help
EOF
}

while getopts ":n:m:r:h" opt; do
  case "$opt" in
    n) MAX_ITERS="$OPTARG" ;;
    m) MODEL_ID="$OPTARG" ;;
    r) REASONING_EFFORT="$OPTARG" ;;
    h) usage; exit 0 ;;
    \?) echo "Unknown flag: -$OPTARG"; usage; exit 1 ;;
    :)  echo "Missing value for -$OPTARG"; usage; exit 1 ;;
  esac
done

if [[ -z "${MAX_ITERS}" ]]; then
  echo "ERROR: -n <iterations> is required."
  usage
  exit 1
fi

if [[ ! -f "prd.json" ]]; then
  echo "ERROR: prd.json not found in the current directory."
  exit 1
fi

touch progress.txt

# Ensure plans directory exists (recommended to gitignore "plans/")
mkdir -p plans

# ---------------------------------------------------------
# Pick next failing PRD item (highest priority if present)
# ---------------------------------------------------------
pick_next_item() {
python3 - <<'PY'
import json, sys, math

with open("prd.json", "r", encoding="utf-8") as f:
    data = json.load(f)

if isinstance(data, list):
    items = data
    struct_type = "list"
elif isinstance(data, dict) and isinstance(data.get("items"), list):
    items = data["items"]
    struct_type = "dict_items"
else:
    print("ERROR: prd.json must be a list or a dict with an 'items' list.", file=sys.stderr)
    sys.exit(2)

failing = [(i, it) for i, it in enumerate(items) if it.get("passes") is False]
if not failing:
    print(struct_type)
    print("-1")
    print("{}")
    sys.exit(0)

def prio(it):
    p = it.get("priority")
    try:
        return float(p)
    except Exception:
        return math.inf

best_i, best_it = min(failing, key=lambda t: (prio(t[1]), t[0]))

print(struct_type)
print(str(best_i))
print(json.dumps(best_it, ensure_ascii=False))
PY
}

# ---------------------------------------------------------
# Mark item passed (runner only)
# ---------------------------------------------------------
mark_item_passed() {
  local struct_type="$1"
  local idx="$2"

python3 - <<PY
import json, sys

struct_type = "${struct_type}"
idx = int("${idx}")

with open("prd.json", "r", encoding="utf-8") as f:
    data = json.load(f)

if struct_type == "list":
    items = data
elif struct_type == "dict_items":
    items = data["items"]
else:
    print("ERROR: Unknown prd.json structure", file=sys.stderr)
    sys.exit(2)

if idx < 0 or idx >= len(items):
    print("ERROR: PRD index out of range", file=sys.stderr)
    sys.exit(2)

items[idx]["passes"] = True

with open("prd.json", "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
    f.write("\n")
PY
}

# ---------------------------------------------------------
# Create per-PRD temp plan file: plans/<index>_<slug>_plan.md
# ---------------------------------------------------------
make_plan_file_path() {
  local idx="$1"
  local item_json="$2"

  PRD_INDEX="$idx" ITEM_JSON="$item_json" python3 - <<'PY'
import json, os, re
idx = int(os.environ["PRD_INDEX"])
item = json.loads(os.environ["ITEM_JSON"])
name = item.get("name") or item.get("feature") or item.get("title") or f"prd_{idx}"
slug = re.sub(r'[^a-zA-Z0-9]+', '_', name).strip('_').lower()
print(f"plans/{idx:03d}_{slug}_plan.md")
PY
}

# ---------------------------------------------------------
# Quality gates (deterministic, run outside the agent)
# ---------------------------------------------------------
run_quality_gates() {
  local iter="$1"
  local ok=0

  echo "Running Quality Gates..."

  if [[ -d "backend" ]]; then
    echo "  -> Backend gate"
    pushd backend >/dev/null
    {
      uv run ruff format --check .
      uv run ruff check .
      uv run pytest -q
    } > "../.ralph_backend_gate_iter_${iter}.log" 2>&1 || ok=1
    popd >/dev/null
  fi

  if [[ -d "frontend" ]]; then
    echo "  -> Frontend gate"
    pushd frontend >/dev/null
    {
      npm run lint
      if node -e 'const p=require("./package.json"); process.exit(p.scripts && p.scripts.typecheck ? 0 : 1)'; then
        npm run typecheck
      fi
      if node -e 'const p=require("./package.json"); process.exit(p.scripts && p.scripts.test ? 0 : 1)'; then
        npm test
      fi
    } > "../.ralph_frontend_gate_iter_${iter}.log" 2>&1 || ok=1
    popd >/dev/null
  fi

  return $ok
}

echo "Starting Ralph [Model: ${MODEL_ID} | Reasoning(label): ${REASONING_EFFORT} | Max iters: ${MAX_ITERS}]"

for ((i=1; i<=MAX_ITERS; i++)); do
  echo
  echo "==================================================="
  echo "Iteration $i of $MAX_ITERS"
  echo "==================================================="

  { read -r STRUCT_TYPE; read -r INDEX; read -r ITEM_JSON; } < <(pick_next_item)

  if [[ "${INDEX}" == "-1" ]]; then
    echo "All tasks in prd.json passed. Exiting."
    exit 0
  fi

  PLAN_FILE="$(make_plan_file_path "$INDEX" "$ITEM_JSON")"
  : > "${PLAN_FILE}"  # truncate/create

  read -r -d '' PROMPT <<EOF || true
You are Ralph, an autonomous coding agent running in a loop (Iteration $i).
Reasoning effort (label): ${REASONING_EFFORT}

TARGET TASK (work ONLY on this one item):
${ITEM_JSON}

CONTEXT FILES:
- prd.json (READ ONLY)
- progress.txt (append ONE brief entry at the end)

FIRST STEP (required):
1) Write an implementation plan into this file (do not commit it):
   ${PLAN_FILE}
   The plan must be <= 15 bullets and include:
   - files to edit
   - tests to add/change
   - commands to run
   - edge cases

STACK:
- Backend: Python + FastAPI. Use uv for Python packages.
  - Activate venv (macOS): source .venv/bin/activate
  - Install python deps with: uv add <package>
  - Prefer running tools via: uv run <cmd>
- Frontend: Node + TypeScript.

RULES:
1) Work only on this task.
2) Do NOT edit prd.json passes. The runner updates that after gates pass.
3) Use git to keep scope tight (read-only usage is fine):
   - git status
   - git diff
   - git log -n 5 --oneline
4) Do not commit (git may be blocked). Focus on producing a clean diff.
5) At the end, append ONE entry to progress.txt:
   - timestamp
   - PRD index
   - what changed
   - how verified (what you ran, if anything)
EOF

  codex exec \
    --model "${MODEL_ID}" \
    --output-last-message "codex_last_message_iter_${i}.txt" \
    "$PROMPT"

  if run_quality_gates "$i"; then
    echo "Gates passed."
    mark_item_passed "$STRUCT_TYPE" "$INDEX"
    echo "Marked PRD item #${INDEX} as passed (prd.json updated by runner)."

    if ! grep -q '"passes"[[:space:]]*:[[:space:]]*false' prd.json; then
      echo "All tasks passed. Exiting."
      break
    fi
  else
    echo "Gates failed. Feeding logs back to Codex for a repair pass."

    BACKLOG_LOG="$(tail -n 200 ".ralph_backend_gate_iter_${i}.log" 2>/dev/null || true)"
    FRONTLOG_LOG="$(tail -n 200 ".ralph_frontend_gate_iter_${i}.log" 2>/dev/null || true)"

    read -r -d '' REPAIR_PROMPT <<EOF || true
Fix the failing quality gates for ONLY this PRD item:
${ITEM_JSON}

Plan file (update if needed, do not commit):
${PLAN_FILE}

Gate outputs:
BACKEND LOG (tail):
${BACKLOG_LOG}

FRONTEND LOG (tail):
${FRONTLOG_LOG}

Rules:
- Smallest change that makes gates pass.
- Use git status/diff to inspect what changed.
- Do not edit prd.json passes.
- Append ONE brief entry to progress.txt describing what you fixed.
EOF

    codex exec \
      --model "${MODEL_ID}" \
      --output-last-message "codex_repair_last_message_iter_${i}.txt" \
      "$REPAIR_PROMPT"
  fi

  sleep 2
done

echo "Ralph loop finished."
