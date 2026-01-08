# Ralph Wiggum Loop

Run a simple loop that repeatedly executes the same Codex prompt, while letting you define project-specific rules in `AGENTS.md`.

Credit: Inspired by the Ralph Wiggum framework by Geoffrey Huntley.

## Requirements
- Codex CLI available on your PATH (`codex`)
- Bash-compatible shell

## Quick start
```sh
./ralph.sh -p "your prompt here" -n 3
```

Optional flags:
- `-m <model>`: model id (default: `gpt-5.2-codex`)
- `-r <reasoning>`: reasoning label (stored in prompt only)

Example:
```sh
./ralph.sh -p "refactor the utils module for clarity" -n 5 -m gpt-5.2-codex -r medium
```

## How the loop works
- Runs the same prompt `n` times.
- Writes the last response from each iteration to `codex_last_message_iter_<n>.txt`.
- Keeps the script minimal so your repo-specific rules live in `AGENTS.md`.

## Configure your agent (AGENTS.md)
Put your project-specific guidance in `AGENTS.md`. The loop is intentionally dumb; your instructions should teach the agent how to work in your repo.

Recommended items to include:
- Preferred stack and libraries (frameworks, packages, SDKs).
- Environment setup (venv/uv/conda, Node manager, etc.).
- Required commands to run (formatters, linters, tests).
- Git workflow expectations:
  - Check `git status`/`git diff` at the start to understand progress.
  - Keep diffs focused; avoid unrelated refactors.
  - Create a commit at the end of each loop iteration (if allowed).
- Any safety or scope rules (files to avoid, directories to ignore, etc.).

Example guidance snippet:
```md
- Use Python 3.12 with uv. Activate venv: `source .venv/bin/activate`.
- Use pnpm for Node. Run `pnpm lint` and `pnpm test` before finishing.
- Start each loop with `git status` and `git diff`.
- Create a commit with a clear message at the end of each loop.
```

## Notes
- This script does not read `prd.json` or manage tasks; it only loops a single prompt.
