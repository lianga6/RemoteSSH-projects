# Workspace Agent Conventions

- **Default Git Scope**: When working in this workspace, any general request to run `git` (status, commit, push, diff, etc.) refers to the **currently mounted remote project** (executed via SSH in `<remote_workspace>/<project_name>`), **NOT** this `RemoteSSH-projects` hub repository—unless the user explicitly says to operate on this remote-connection hub project itself.
- **Mount Isolation**: Mounted remote project folders inside this directory are ignored by `.gitignore` and must never be committed to `RemoteSSH-projects`.
