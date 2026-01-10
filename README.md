# Ralph Wiggum Loop

Run a simple loop that repeatedly executes the same Codex prompt, while letting you define project-specific rules in `AGENTS.md`.

Credit: Inspired by the Ralph Wiggum loop by Geoffrey Huntley.

## Requirements
- Codex CLI available on your PATH (`codex`)
- Bash-compatible shell

## Quick start
1) Install Codex CLI: [Codex Docs](https://developers.openai.com/codex/cli/)

2) Copy the example config:
```sh
cp .codex/config.example.toml .codex/config.toml
```

3) Open `.codex/config.toml` and replace the project path inside the brackets with your local repo path.

4) Edit `PROMPT.md` with the prompt you want to run in the loop.

5) Make the script executable and run it:
```sh
chmod +x ralph.sh
./ralph.sh -n 3
```
`-n` is the number of loop iterations.

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

## Safety & security
- This loop can modify files and run commands depending on how you configure Codex. Prefer running it in a sandboxed environment or VM.
- `danger-full-access` gives the agent broad permissions; only use it when you explicitly want that (for example, to allow creating git commits).
- Review the Codex safety and security documentation before using: [Codex Docs](https://developers.openai.com/codex/security)


## Cost warning
If you run Codex via the API, be mindful of usage costs. Repeated loops can rack up charges quickly. It is recommended to use your OpenAI user account (or a dedicated account) with clear billing limits.

## Gemini CLI Support

This repository also supports the Gemini CLI via `ralph-gemini.sh`.

### Quick start
1) Install Gemini CLI: [Gemini CLI Docs](https://gemini-cli.com/)

2) Edit `.gemini/settings.json` to configure your model and sandbox settings.
   Default:
   ```json
   {
     "model": "gemini-3-pro-preview",
     "sandbox": true
   }
   ```

3) Edit `PROMPT.md` with your task.

4) Run the loop:
```sh
chmod +x ralph-gemini.sh
./ralph-gemini.sh -n 3
```

The script runs in "YOLO" mode (autonomous) by default. Use `.gemini/settings.json` or the `-m` flag to adjust settings.