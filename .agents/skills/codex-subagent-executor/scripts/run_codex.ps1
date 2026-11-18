<#
.SYNOPSIS
  Probe or execute Codex CLI in non-interactive (headless) mode, locally or over SSH,
  with quota/rate-limit detection.
#>
param(
    [switch]$Probe,
    [string]$Prompt,
    [string]$PromptFile,
    [string]$Model = "gpt-6.1-sol",
    [string]$ReasoningEffort = "medium",
    [string]$WorkDir = (Get-Location).Path,
    [string]$SshTarget,
    [string]$Subcommand = "exec",
    [string[]]$ExtraArgs = @("--full-auto")
)

$ErrorActionPreference = "Stop"

function Test-CodexFallback {
    param([int]$ExitCode, [string]$OutputText)
    if ($ExitCode -ne 0 -and $OutputText -match "(?i)(429|rate[ _-]?limit|quota|insufficient_quota|context_length_exceeded|maximum context length|token.*overflow)") {
        Write-Warning "CODEX_FALLBACK_TRIGGERED: Detected quota/rate-limit/token-overflow error (exit=$ExitCode). Stop retrying Codex and fall back to Gemini."
    }
}

if ($SshTarget) {
    $sshCmd = Get-Command ssh -ErrorAction SilentlyContinue
    if (-not $sshCmd) {
        Write-Error "SSH_NOT_FOUND: 'ssh' CLI was not found in PATH."
        exit 127
    }

    if ($Probe) {
        $probeScript = "which codex && codex --version && codex --help | head -n 35 && echo '=== EXEC ===' && codex $Subcommand --help | head -n 35"
        $output = & ssh -n -o BatchMode=yes $SshTarget $probeScript 2>&1
        $output | Write-Output
        exit $LASTEXITCODE
    }

    if ($PromptFile) {
        if (-not (Test-Path $PromptFile)) {
            Write-Error "PromptFile not found: $PromptFile"
            exit 2
        }
        $Prompt = Get-Content -Raw -Encoding UTF8 $PromptFile
    }

    if ([string]::IsNullOrWhiteSpace($Prompt)) {
        Write-Error "Provide -Prompt or -PromptFile (or use -Probe)."
        exit 2
    }

    # Base64-encode UTF-8 prompt to avoid shell quoting issues and keep stdin closed (-n).
    $promptB64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($Prompt))
    $extraJoined = ($ExtraArgs | ForEach-Object { "'$_'" }) -join " "
    $reasoningArg = if ($ReasoningEffort) { "-c model_reasoning_effort=$ReasoningEffort" } else { "" }
    $remoteCmd = "cd '$WorkDir' && CODEX_PROMPT=`$(printf '%s' '$promptB64' | base64 -d) && codex $Subcommand -m '$Model' $reasoningArg $extraJoined `"`$CODEX_PROMPT`""

    $output = & ssh -n -o BatchMode=yes $SshTarget $remoteCmd 2>&1
    $exitCode = $LASTEXITCODE
    $joined = ($output | Out-String)
    Write-Output $joined
    Test-CodexFallback -ExitCode $exitCode -OutputText $joined
    exit $exitCode
}

$codexCmd = Get-Command codex -ErrorAction SilentlyContinue
if (-not $codexCmd) {
    Write-Error "CODEX_NOT_FOUND: 'codex' CLI was not found in local PATH. Install it locally or pass -SshTarget <user>@<host>."
    exit 127
}

if ($Probe) {
    Write-Output "CODEX_PATH: $($codexCmd.Source)"
    Write-Output "--- codex --version ---"
    & codex --version 2>&1 | Write-Output
    Write-Output "--- codex --help (head) ---"
    (& codex --help 2>&1 | Select-Object -First 40) | Write-Output
    Write-Output "--- codex $Subcommand --help (head) ---"
    (& codex $Subcommand --help 2>&1 | Select-Object -First 40) | Write-Output
    exit 0
}

if ($PromptFile) {
    if (-not (Test-Path $PromptFile)) {
        Write-Error "PromptFile not found: $PromptFile"
        exit 2
    }
    $Prompt = Get-Content -Raw -Encoding UTF8 $PromptFile
}

if ([string]::IsNullOrWhiteSpace($Prompt)) {
    Write-Error "Provide -Prompt or -PromptFile (or use -Probe)."
    exit 2
}

Push-Location $WorkDir
try {
    $argsList = @()
    if (-not [string]::IsNullOrWhiteSpace($Subcommand)) {
        $argsList += $Subcommand
    }
    $argsList += @("-m", $Model)
    if ($ReasoningEffort) {
        $argsList += @("-c", "model_reasoning_effort=$ReasoningEffort")
    }
    if ($ExtraArgs) {
        $argsList += $ExtraArgs
    }
    $argsList += $Prompt

    $output = & codex @argsList 2>&1
    $exitCode = $LASTEXITCODE
    $joined = ($output | Out-String)

    Write-Output $joined
    Test-CodexFallback -ExitCode $exitCode -OutputText $joined
    exit $exitCode
}
finally {
    Pop-Location
}
