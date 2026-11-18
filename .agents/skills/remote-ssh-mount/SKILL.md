---
name: remote-ssh-mount
description: >-
  Mount a remote project from an SSH server (<user>@<host> or SSH config alias)
  into the local workspace via SSHFS-Win and execute all project terminal
  commands over SSH in the remote project directory. Use this skill whenever the
  user opens this workspace and specifies a remote project to work on, asks to
  mount a remote project, or wants to run commands on the remote server.
---

# Remote SSH Mount & Terminal Workflow

This workspace is a local hub for working on remote Linux projects over SSH + SSHFS-Win.

## Defaults & Local Configuration

- **SSH target**: Use the `<user>@<host>` (or SSH alias in `~/.ssh/config`) provided by the user or stored in a local gitignored config file (never commit real IPs or usernames to this repository).
- **Remote projects root**: `<remote_workspace>` (e.g., `/home/<user>/workspace`, unless the user provides an absolute path).
- **SSHFS executable**: `C:\Program Files\SSHFS-Win\bin\sshfs.exe`
- **Bundled SSH binary**: `/usr/bin/ssh` (required via `-o ssh_command="/usr/bin/ssh"` because Windows' built-in OpenSSH has a socketpair/pipe incompatibility with Cygwin-based `sshfs.exe`).

## Step 1: Identify the Remote Project

1. If the user provides a project name (e.g. `my_project`), the remote path is `<remote_workspace>/<project_name>` and the local mount point is `<workspace_root>/<project_name>`.
2. If the user provides an absolute remote path (starting with `/`), use it directly and use its basename as `<project_name>`.
3. If the user hasn't specified a project name or wants to see available projects, list the remote workspace:
   ```powershell
   ssh -o BatchMode=yes <user>@<host> "ls -1 <remote_workspace>"
   ```
   *(Run with `BypassSandbox: true` since SSH requires network access.)*

## Step 2: Mount the Project Locally via SSHFS-Win

1. **Check if already mounted**:
   Run (with `BypassSandbox: true`):
   ```powershell
   Test-Path "<workspace_root>\<project_name>"
   ```
   If it exists and `Get-ChildItem` succeeds with remote files, it is already mounted — skip to Step 3.
   If an empty stale directory exists (not mounted), remove it first (`Remove-Item`), because WinFsp requires the mount point directory not to exist beforehand.

2. **Start SSHFS daemon**:
   Use forward slashes for the local mount point path and run as a background daemon (`IsDaemon: true`, `BypassSandbox: true`):
   ```powershell
   & "C:\Program Files\SSHFS-Win\bin\sshfs.exe" -f <user>@<host>:<remote_workspace>/<project_name> "<workspace_root_forward_slashes>/<project_name>" -o ssh_command="/usr/bin/ssh" -o reconnect -o ServerAliveInterval=15 -o ServerAliveCountMax=3
   ```

3. **Verify the mount**:
   Run with `BypassSandbox: true`:
   ```powershell
   Get-ChildItem "<workspace_root>\<project_name>" | Select-Object -First 10 Name, Mode
   ```
   *(Note: WinFsp FUSE mount points may return `Access denied` inside the restricted sandbox, so verify and run filesystem commands on the mounted path with `BypassSandbox: true` if needed.)*

## Step 3: Use Remote SSH Terminal for All Project Commands

Once the project is identified/mounted, treat the terminal as a **remote SSH terminal** inside that project:

- **Every project command** (`git`, `python`, `pytest`, `pip`, `bash`, build/test/train scripts, etc.) must be executed on the remote server inside the project directory via SSH (`BypassSandbox: true`):
  ```powershell
  ssh <user>@<host> "cd <remote_workspace>/<project_name> && <command>"
  ```
- For interactive or multi-line remote shell commands, pass them via `bash -lc`:
  ```powershell
  ssh <user>@<host> "cd <remote_workspace>/<project_name> && bash -lc '<command>'"
  ```
- You can inspect and edit files directly through the mounted path `<workspace_root>\<project_name>\...`, while running all execution, environment, and git operations on the remote server over SSH.

## Unmounting

To unmount a mounted project, kill the corresponding `sshfs.exe` daemon task (via `manage_task` or Task Manager).
