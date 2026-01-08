#!/usr/bin/env bash
set -euo pipefail

MODEL_ID="gpt-5.2-codex"
REASONING_EFFORT="medium"
MAX_ITERS=""

cleanup(){ [[ -d plans ]] && rm -rf plans; }
trap cleanup EXIT INT TERM

usage(){ echo 'Usage: ./ralph.sh -n <iters> [-m <model>] [-r <reasoning>]'; }

while getopts ":n:m:r:h" opt; do
  case "$opt" in
    n) MAX_ITERS="$OPTARG" ;;
    m) MODEL_ID="$OPTARG" ;;
    r) REASONING_EFFORT="$OPTARG" ;;
    h) usage; exit 0 ;;
    \?) echo "Bad flag -$OPTARG"; usage; exit 1 ;;
    :)  echo "Missing value -$OPTARG"; usage; exit 1 ;;
  esac
done

[[ -z "${MAX_ITERS}" ]] && { echo "ERROR: -n required"; usage; exit 1; }
[[ ! -f prd.json ]] && { echo "ERROR: prd.json missing"; exit 1; }

touch progress.txt
mkdir -p plans

pick_next_item(){
python3 - <<'PY'
import json,sys,math
d=json.load(open("prd.json","r",encoding="utf-8"))
items=d if isinstance(d,list) else d.get("items")
if not isinstance(items,list):
  print("ERR prd.json",file=sys.stderr); sys.exit(2)
fail=[(i,it) for i,it in enumerate(items) if it.get("passes") is False]
if not fail:
  print("list" if isinstance(d,list) else "dict_items"); print("-1"); print("{}"); sys.exit(0)
def prio(it):
  p=it.get("priority")
  try: return float(p)
  except: return math.inf
i,it=min(fail,key=lambda t:(prio(t[1]),t[0]))
print("list" if isinstance(d,list) else "dict_items"); print(i); print(json.dumps(it,ensure_ascii=False))
PY
}

mark_item_passed(){
  local struct="$1" idx="$2"
python3 - <<PY
import json,sys
struct="${struct}"; idx=int("${idx}")
d=json.load(open("prd.json","r",encoding="utf-8"))
items=d if struct=="list" else d["items"]
if idx<0 or idx>=len(items): print("ERR idx",file=sys.stderr); sys.exit(2)
items[idx]["passes"]=True
with open("prd.json","w",encoding="utf-8") as f:
  json.dump(d,f,ensure_ascii=False,indent=2); f.write("\n")
PY
}

run_quality_gates(){
  local iter="$1" ok=0
  [[ -d backend ]] && { pushd backend >/dev/null
    { uv run ruff format --check .; uv run ruff check .; uv run pytest -q; } > "../.ralph_backend_gate_iter_${iter}.log" 2>&1 || ok=1
    popd >/dev/null; }
  [[ -d frontend ]] && { pushd frontend >/dev/null
    { npm run lint
      node -e 'const p=require("./package.json");process.exit(p.scripts&&p.scripts.typecheck?0:1)' && npm run typecheck || true
      node -e 'const p=require("./package.json");process.exit(p.scripts&&p.scripts.test?0:1)' && npm test || true
    } > "../.ralph_frontend_gate_iter_${iter}.log" 2>&1 || ok=1
    popd >/dev/null; }
  return $ok
}

echo "Ralph [model=${MODEL_ID} reason=${REASONING_EFFORT} iters=${MAX_ITERS}]"

for ((i=1;i<=MAX_ITERS;i++)); do
  echo "== Iter $i/$MAX_ITERS =="
  { read -r STRUCT; read -r IDX; read -r ITEM; } < <(pick_next_item)
  [[ "$IDX" == "-1" ]] && { echo "Done"; exit 0; }

  read -r -d '' PROMPT <<EOF || true
Ralph iter $i. Reason(label): ${REASONING_EFFORT}
ONLY TASK: ${ITEM}
Files: prd.json(RO), progress.txt(append 1 entry)
Rules: use uv (source .venv/bin/activate; uv add; uv run). Use node tooling via pnpm/npm as present.
No prd.json passes edits. Use git status/diff/log. No commit. Small diff + tests. Append 1 progress entry (ts, PRD idx, change, verify).
EOF

  codex exec --model "${MODEL_ID}" --output-last-message "codex_last_message_iter_${i}.txt" "$PROMPT"

  if run_quality_gates "$i"; then
    mark_item_passed "$STRUCT" "$IDX"
    grep -q '"passes"[[:space:]]*:[[:space:]]*false' prd.json || break
  else
    L1="$(tail -n 120 ".ralph_backend_gate_iter_${i}.log" 2>/dev/null || true)"
    L2="$(tail -n 120 ".ralph_frontend_gate_iter_${i}.log" 2>/dev/null || true)"
    read -r -d '' REPAIR <<EOF || true
Fix ONLY this task: ${ITEM}
LOG1(tail): ${L1}
LOG2(tail): ${L2}
Rules: smallest fix; git status/diff; no prd.json passes edits; append 1 progress entry.
EOF
    codex exec --model "${MODEL_ID}" --output-last-message "codex_repair_last_message_iter_${i}.txt" "$REPAIR"
  fi

  sleep 2
done

echo "Ralph finished"
