# AGENTS.md

You are a coding agent working in this repository.

## Stack preferences
- Prefer Python for backend and full-stack work.
- Frontend: Next.js with Tailwind CSS.

## Python + uv rules (macOS)
- Activate venv: `source .venv/bin/activate`
- Add deps: `uv add <package>`
- Run tools: `uv run <command>`
- Avoid `pip install` unless explicitly instructed.

## Workflow rules
- At the start of each conversation, check progress with:
  - `git status`
  - `git diff`
- Keep diffs small and focused on the requested feature.
- When the feature works, create a commit at the end of the loop with a clear message (if allowed).

## Testing + coverage (minimum 60%)
- Add or update tests for any behavior change (features, bug fixes, refactors that touch logic).
- Aim for at least **60% total code coverage**; if the repo is already above 60%, do not reduce it.

### Python (preferred)
- Add test deps (dev):
  - `uv add --dev pytest pytest-cov`
- Write tests under `tests/` using `pytest`.
- Run tests + enforce coverage:
  - `uv run pytest --cov --cov-report=term-missing --cov-fail-under=60`

### Frontend (Next.js)
- Use the repo’s Node package manager (prefer `pnpm` if present).
- Run tests with coverage and ensure totals are at least 60% (lines/statements):
  - `pnpm test -- --coverage`
