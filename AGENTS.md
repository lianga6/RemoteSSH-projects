# Workspace Agent Conventions

- **Default Remote Project & Automatic Mount**:
  - **Default Target**: `lxl@10.102.137.137:/home/lxl/workspace/task_combination` → local mount point `E:/projects/RemoteSSH-projects/task_combination`.
  - **Auto-Mount Requirement**: Whenever interacting in this workspace, if the project directory is not mounted (e.g. after system, IDE, or server restarts), the agent MUST automatically check and mount it via SSHFS-Win (`& "C:\Program Files\SSHFS-Win\bin\sshfs.exe" -f lxl@10.102.137.137:/home/lxl/workspace/task_combination "E:/projects/RemoteSSH-projects/task_combination" -o ssh_command="/usr/bin/ssh" -o reconnect -o ServerAliveInterval=15 -o ServerAliveCountMax=3 -o uid=-1,gid=-1`) as a background daemon before proceeding.
- **Default Git Scope**: When working in this workspace, any general request to run `git` (status, commit, push, diff, etc.) refers to the **currently mounted remote project** (executed via SSH in `<remote_workspace>/<project_name>`), **NOT** this `RemoteSSH-projects` hub repository—unless the user explicitly says to operate on this remote-connection hub project itself.
- **Mount Isolation**: Mounted remote project folders inside this directory are ignored by `.gitignore` and must never be committed to `RemoteSSH-projects`.
- **Demo Video Links**: Whenever an evaluation, replay, or diagnostic generates demo/rollout videos (e.g., `primary.mp4`), always include clickable `file://` links to those videos in the response.
