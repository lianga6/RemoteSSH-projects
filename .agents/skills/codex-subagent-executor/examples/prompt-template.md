# Codex Structured Dispatch Template

Use this minimal template when delegating a subtask to Codex CLI (`-m gpt-6.1-sol -c model_reasoning_effort=medium`). Keep it concise and free of unrelated conversation history.

## Template

```text
Goal: <One sentence stating what to implement or fix.>

Scope:
- <path/to/file1.py>: <function_or_class_names>
- <path/to/file2.py>: <function_or_class_names>

Constraints:
- <Input/output schema or type requirements>
- <Edge cases to handle>
- <Code style / compatibility rules; do not modify unrelated files>

Verification:
- Run: `<exact test or lint command>`
- Confirm all targeted tests pass and report only changed files + test result.
```

## Example: Good vs. Bad Prompt

### Bad (Wastes GPT Quota)
> Look through the whole repository and understand how our auth and user modules work, then refactor everything to be cleaner and add tests for all edge cases we talked about earlier.

### Good (High Signal-to-Noise)
> Goal: Add exponential backoff retry to `fetch_user_profile` on HTTP 429/5xx errors.
>
> Scope:
> - `src/api/client.py`: `fetch_user_profile`
> - `tests/test_client.py`: add unit tests with mocked responses
>
> Constraints:
> - Max 3 retries; base delay 0.5s; raise `RateLimitError` after exhaustion.
> - Preserve existing function signature and docstring.
>
> Verification:
> - Run: `pytest tests/test_client.py -k fetch_user_profile`
