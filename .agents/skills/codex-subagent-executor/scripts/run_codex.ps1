<#
.SYNOPSIS
  Probe or execute Codex CLI in non-interactive (headless) mode with quota/rate-limit detection.
#>
param(
    [switch]$Probe,
    [string]$Prompt,
    [string]$PromptFile,
    [string]$Model = "gpt6.1-sol-中",
    [string]$WorkDir = (Get-Location).Path,
    [string]$Subcommand = "exec",
    [string[]]$ExtraArgs = @("--full-auto")
)

$ErrorActionPreference = "Stop"

$codexCmd = Get-Command codex -ErrorAction SilentlyContinue
if (-not $codexCmd) {
    Write-Error "CODEX_NOT_FOUND: 'codex' CLI was not found in PATH. Install it or verify PATH before invoking."
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
    if ($ExtraArgs) {
        $argsList += $ExtraArgs
    }
    $argsList += $Prompt

    $output = & codex @argsList 2>&1
    $exitCode = $LASTEXITCODE
    $joined = ($output | Out-String)

    Write-Output $joined

    # Detect quota, rate limit (429), or token overflow for immediate fallback
    if ($exitCode -ne 0 -and $joined -match "(?i)(429|rate[ _-]?limit|quota|insufficient_quota|context_length_exceeded|maximum context length|token.*overflow)") {
        Write-Warning "CODEX_FALLBACK_TRIGGERED: Detected quota/rate-limit/token-overflow error (exit=$exitCode). Stop retrying Codex and fall back to Gemini."
    }

    exit $exitCode
}
finally {
    Pop-Location
}
