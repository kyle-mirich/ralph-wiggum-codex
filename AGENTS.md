# AGENTS.md

You are an autonomous coding agent working inside this repository.

## Mission
Implement exactly one PRD item per iteration. Keep changes small, correct, and verifiable.

## Source of truth
- `prd.json` is the backlog and contains requirements and acceptance criteria.
- Treat `prd.json` as **READ ONLY**.
- The runner script updates `passes: true` after quality gates pass.

## Files you will touch
- Code and tests only (backend and or frontend).
- `progress.txt` (append one brief entry per iteration, do not commit).
- Per-item plan file under `plans/` (write a short plan first, do not commit).

## Planning rule
Before editing any code, you must write a short implementation plan to the plan file path provided by the runner (example: `plans/003_some_feature_plan.md`). Use [] for the plan bullets ,then you can use [x] once the plan item is completed.

Plan requirements:
- Maximum 15 bullets
- Include:
  - files to edit
  - tests to add or update
  - commands to run
  - edge cases or failure modes

Do not maintain a long running planning document. The plan file is per PRD item.

## Preferred stack
- Backend: Python + FastAPI
- Frontend: Node + TypeScript (React)

Principle: AI and business logic belong in the backend. The frontend is UX + API client.

## Python + uv rules (macOS)
This repo uses **uv**. Always work inside the uv-managed environment.

- Activate venv:
  - `source .venv/bin/activate`
- Install dependencies:
  - `uv add <package>`
- Run commands:
  - `uv run <command>`

Avoid `pip install` unless explicitly instructed.

## Node rules
Use the repo’s existing Node tooling.
- If the repo uses `pnpm`, use `pnpm`.
- Otherwise use `npm` consistently.

## Git workflow (inspection only)
Git committing may be blocked by sandbox or permissions. Do not commit unless explicitly instructed.

You must use git to inspect scope:
- `git status`
- `git diff`
- `git log -n 5 --oneline`

Keep diffs tightly scoped to the single PRD item.

## Quality expectations
The runner enforces gates, but you should still run what is helpful locally if possible.

Backend gates when backend changes:
- `uv run ruff format --check .`
- `uv run ruff check .`
- `uv run pytest -q`

Frontend gates when frontend changes:
- `npm run lint` (or `pnpm lint`)
- `npm run typecheck` (if present)
- `npm test` (if present)

## Scope and safety rules
- Work only on the PRD item provided in the runner prompt.
- Do not work ahead on other items.
- Do not refactor unrelated code.
- Do not change `passes` in `prd.json`.
- Do not commit:
  - `prd.json`
  - files under `plans/`
  - `progress.txt`

## progress.txt format
Append exactly one entry at the end of the iteration:

- timestamp
- PRD index
- what changed
- how verified

Example:

[2026-01-07T18:42:10-08:00] PRD #3
- Change: Added /v1/health endpoint and test
- Verify: uv run ruff check . ; uv run pytest -q
- Notes: none

If blocked, include what failed and what you tried.
