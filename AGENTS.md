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
