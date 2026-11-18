---
name: codex-subagent-executor
description: >-
  Orchestrate local Codex CLI as a headless subagent executor from Gemini
  (master planner) using a master-worker pattern. Use this skill whenever a task
  involves multi-file code generation, large refactoring, unit test authoring,
  batch edits, boilerplate generation, or complex bug fixing where delegating
  implementation to Codex CLI (-m gpt6.1-sol-中) saves Gemini context/quota
  while protecting GPT quota through compressed, structured prompts.
---

# Codex Subagent Executor (Master–Worker Pattern)

Use **Gemini** as the master planner (requirement analysis, task decomposition, context curation, final review) and **Codex CLI** as the headless worker (code writing, refactoring, batch edits, test execution).

## 1. Model & Headless CLI Defaults (Mandatory)

- **Default Model**: `gpt6.1-sol-中` (user-configurable—you may change the default GPT/Codex model in this file or `scripts/run_codex.ps1` to any preferred model, passed via `-m <model>`).
- **Model Escalation (Requires User Approval)**: If Gemini determines that a task exceeds `gpt6.1-sol-中`'s capability (e.g., intricate cross-module architecture, subtle concurrency/algorithm bugs, or correctness failures after clear prompts), **do not** switch models silently. Pause and ask the user for permission to use a stronger Codex model, stating the reason and the target subtask; once approved, pass the user-specified model via `-Model "<model_name>"`.
- **Headless / Non-Interactive Only**: Always invoke Codex in non-interactive mode (e.g., `codex exec ...` or `--quiet` / `--full-auto` depending on the installed CLI version). **NEVER** launch the interactive TUI (`codex` without headless subcommand/flags), as it blocks the terminal.
- **Working Directory**: Run inside the target project root (if working on a mounted remote project, check whether `codex` should run locally on the mounted path or over SSH if `codex` is installed on the remote host).

## 2. Task Routing Decision Tree

Before invoking Codex, evaluate quota ROI:

| Delegate to Codex (Worker) | Handle Directly in Gemini (Save GPT Quota) |
| :--- | :--- |
| Multi-file code generation | Single-line or few-line edits |
| Large logic refactoring | Pure architecture / design discussion |
| Writing unit / integration tests | Simple status or git queries |
| Batch file modifications | Reading a small config or single snippet |
| Complex bug localization & fixing | Explaining existing code |
| Boilerplate / scaffolding generation | |

## 3. GPT Quota Protection (Context Compression)

1. **No Full-Repo Feeding**: Never instruct Codex to scan an entire large codebase, and never paste unrelated chat history into the prompt.
2. **Structured Dispatch Template**: Before calling Codex, distill the task into a high-signal-to-noise prompt using [prompt-template.md](./examples/prompt-template.md) containing:
   - **Goal**: One sentence describing the exact outcome.
   - **Scope**: Exact file paths and symbol/function names.
   - **Constraints**: I/O formats, edge cases, coding conventions.
   - **Verification**: Exact command(s) Codex must run to self-test.
3. **Granularity Limit**: If a task spans too many concerns, split it into **2–4 independent subtasks** and dispatch them sequentially. Do not overload a single Codex invocation.

## 4. Standard Operating Procedure (SOP)

### Step 1: Assess Complexity & Quota ROI
Decide via Section 2 whether to handle directly in Gemini or delegate to Codex. If delegating and the task is large, break it into 2–4 focused subtasks first.

### Step 2: Probe Local `codex` CLI (First Run per Session)
Verify the `codex` binary path and exact CLI flags before dispatching work:
```powershell
powershell -ExecutionPolicy Bypass -File .\.agents\skills\codex-subagent-executor\scripts\run_codex.ps1 -Probe
```
Confirm the exact flags for:
- Model selection (must pass `gpt6.1-sol-中`)
- Non-interactive execution (`exec` / `--quiet`)
- Auto-approval / sandbox mode (`--full-auto` / `--approval-mode` / `--sandbox`)

### Step 3: Build Minimal Prompt & Execute Headlessly
Pass the compressed structured prompt via [run_codex.ps1](./scripts/run_codex.ps1) (or the verified `codex exec -m gpt6.1-sol-中 ...` command), capturing stdout/stderr and exit code:
```powershell
powershell -ExecutionPolicy Bypass -File .\.agents\skills\codex-subagent-executor\scripts\run_codex.ps1 `
  -WorkDir "<project_path>" `
  -Prompt "<compressed_structured_prompt>"
```

### Step 4: Fast Code Review & Report
After Codex finishes:
1. Run `git diff --stat` and `git diff` (or inspect only the modified line ranges) — **do not** re-read entire unmodified files in Gemini to avoid wasting Gemini quota.
2. Verify the acceptance command passed.
3. Report the concise outcome and diff summary to the user.

## 5. Exception Handling & Fallback

Monitor the `codex` CLI **Exit Code** and **stderr**:
- Trigger **immediate fallback** if any of the following occur:
  - Quota exceeded / insufficient quota
  - Rate Limit (`429` / `rate limit`)
  - Context / Token overflow (`context_length_exceeded` / `maximum context length`)
  - **2 consecutive execution failures**
- **Fallback action**: Stop retrying Codex immediately. Report current progress and the exact error to the user:
  - For quota/rate-limit/token-overflow errors, switch to Gemini to complete the remaining steps or await user instructions.
  - For repeated logic/correctness failures where `gpt6.1-sol-中` appears underpowered for the task, explicitly ask the user whether to escalate to a stronger Codex model (specifying which model/subtask) or let Gemini take over.
