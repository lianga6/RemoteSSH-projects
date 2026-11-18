# RemoteSSH-projects

A local Windows workspace hub for mounting and operating remote Linux projects over **SSH + SSHFS-Win**, paired with Antigravity Agent Skills for remote project workflows and headless Codex subagent delegation.

## Included Skills

### 1. `remote-ssh-mount`
- **Path**: [`.agents/skills/remote-ssh-mount/SKILL.md`](./.agents/skills/remote-ssh-mount/SKILL.md)
- **Purpose**: Mounts a remote project from your SSH server (`<user>@<host>:<remote_workspace>/<project>`) into a local subfolder (`./<project>`) via `SSHFS-Win` and routes all project terminal commands (`git`, `python`, `pytest`, build/train scripts, etc.) over SSH in the remote directory.
- **Prerequisites (Windows)**:
  - `WinFsp` (`winget install --id WinFsp.WinFsp -e`)
  - `SSHFS-Win` (`winget install --id SSHFS-Win.SSHFS-Win -e`)
  - Passwordless SSH key auth configured for your target host (recommended via an alias in `~/.ssh/config`)

### 2. `codex-subagent-executor`
- **Path**: [`.agents/skills/codex-subagent-executor/SKILL.md`](./.agents/skills/codex-subagent-executor/SKILL.md)
- **Purpose**: Master–worker orchestration where Gemini handles planning, task decomposition, and final `git diff` review while delegating heavy implementation (multi-file generation, refactoring, unit tests, batch edits) to headless `codex` CLI with compressed prompts and automatic quota/rate-limit fallback.
- **Customizable Default Model**: You can choose your own default GPT/Codex model and reasoning effort by setting `-Model` / `-ReasoningEffort` in [`run_codex.ps1`](./.agents/skills/codex-subagent-executor/scripts/run_codex.ps1) or updating the defaults in `SKILL.md` (currently preset to `gpt-6.1-sol` with `model_reasoning_effort=medium` as an example; supports both local and `-SshTarget` remote execution).

## Git Scope Convention

- All mounted project directories are **ignored** by [`.gitignore`](./.gitignore) and are never committed to this repository.
- By default, any `git` commit/push request in this workspace targets the **mounted remote project** over SSH, not this hub repository, unless explicitly specified otherwise.
