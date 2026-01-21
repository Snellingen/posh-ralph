# Ralph quickstart

## Install the module
1. Install to your PowerShell modules path (per-user):
   ```powershell
   # From repo root
   pwsh -File ./Install-RalphModule.ps1
   Get-Command -Module PoshRalph
   ```
   Options: `-Force` to overwrite; `-Scope AllUsers` (admin) to install globally.

## Initialize a project for Ralph
Run the setup command in the target repo (adds prompts, plans, progress):
```powershell
# Navigate to your project
cd /path/to/your/project

# Set up Ralph project files
Setup-RalphProject

# Overwrite existing files if needed
Setup-RalphProject -Force
```

This creates/updates:
- prompts/default.txt
- plans/prd.json
- plans/prd.schema.json
- progress.txt
- test-coverage-progress.txt

## Run Ralph
From the project root:
```powershell
Invoke-RalphCopilot -PromptFile "prompts/default.txt" -PrdFile "plans/prd.json" -AllowProfile safe
```
Optional:
- Add `-Skills wp-project-triage` (or any folder under skills/ with SKILL.md).
- Use `-Model <model>` to specify a model (has auto-complete support, e.g., `-Model claude-haiku-4.5`).
- Alternatively, set `$env:MODEL` to override the default model.

## Requirements
- PowerShell 7+
- GitHub Copilot CLI available on PATH (`copilot --help`)

## Notes
- The setup files are templates; edit prompts and PRDs to match your work.
- `progress.txt` must remain in the repo root; the command fails if it is missing.
- PRD schema: plans/prd.schema.json (JSON Schema, draft-07) — validate your PRDs with your preferred JSON schema tool.
