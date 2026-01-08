# AGENTS.md

You are an autonomous coding agent working inside this repository.

## Primary rule
- Work on **one `prd.json` item at a time** (the runner provides the target item).

## Source of truth
- `prd.json` is the backlog and acceptance criteria.
- Treat `prd.json` as **READ ONLY**.
- Never edit `passes`. The runner updates it after gates pass.

## Scope
- Keep diffs small and directly related to the target item.
- Do not refactor unrelated code.
- Do not work ahead on other items.

## Files
- You may edit code + tests.
- Append exactly **one** entry per iteration to `progress.txt` (do not commit it).
- Do not create extra docs unless required by the PRD item.

## Git (inspection only)
- Use git to keep scope tight:
  - `git status`
  - `git diff`
  - `git log -n 5 --oneline`
- Do not commit unless explicitly instructed (commits may be blocked).

## Python + uv (macOS)
- Activate env: `source .venv/bin/activate`
- Add deps: `uv add <package>`
- Run tools: `uv run <command>`
- Avoid `pip install` unless explicitly told to.

## Node tooling
- Use repo tooling:
  - If `pnpm-lock.yaml` exists, use `pnpm`.
  - Otherwise use `npm`.

## Verify
- Run the relevant checks/tests locally when possible.
- If you changed Python, prefer:
  - `uv run ruff format --check .`
  - `uv run ruff check .`
  - `uv run pytest -q`
- If you changed Node/TS, prefer:
  - `pnpm lint` / `npm run lint`
  - `pnpm typecheck` / `npm run typecheck` (if present)
  - `pnpm test` / `npm test` (if present)

## progress.txt format
Append one entry at the end of the iteration:

[ISO_TIMESTAMP] PRD #<index>
- Change: <what you changed>
- Verify: <commands you ran or “runner gates”>
- Notes: <errors, blockers, assumptions>

Example:
[2026-01-07T18:42:10-08:00] PRD #3
- Change: Added /health endpoint + test
- Verify: uv run pytest -q; uv run ruff check .
- Notes: none

## If blocked
- Record the exact error and what you tried in `progress.txt`.
- Keep the working tree in a debuggable state (small, clear diffs).
