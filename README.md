# posh-ralph — PowerShell version of the AI Ralph loop CLI

> Let AI implement your features while you sleep — **now on Windows with PowerShell**.

**posh-ralph** is a PowerShell implementation of the Ralph loop command-line tool. It runs **GitHub Copilot CLI** in a loop, implementing one feature at a time until your PRD is complete.

This repository targets **Windows (PowerShell 7+)** as the primary platform and aims to remain **cross-platform** when run with **PowerShell 7+** on Linux/macOS.

⚠️ **Note:** Linux/macOS are **not tested** in this repository at this time.

[Quick Start](#quick-start) · [How It Works](#how-it-works) · [Requirements](#requirements) · [Installation](#installation) · [Usage](#usage) · [Configuration](#configuration) · [Command Reference](#command-reference) · [Cross-Platform](#cross-platform-note)

---

## Quick Start

```powershell
# 1. Install the module
git clone https://github.com/Snellingen/posh-ralph
cd posh-ralph
pwsh -File ./Install-RalphModule.ps1

# 2. Set up Ralph in your project
cd /path/to/your/project
Setup-RalphProject

# 3. Edit your work items in plans/prd.json

# 4. Run Ralph with a single iteration
Invoke-Ralph -PromptFile prompts/default.txt -PrdFile plans/prd.json -AllowProfile safe

# 5. Run multiple iterations
Invoke-RalphCopilot -PromptFile prompts/default.txt -PrdFile plans/prd.json -AllowProfile safe -Iterations 10
```

Check `progress.txt` for a log of what was done.

---

## How It Works

Ralph implements the ["Ralph Wiggum" technique](https://www.humanlayer.dev/blog/brief-history-of-ralph):

1. **Read** — Copilot reads your PRD (if attached) and progress file
2. **Pick** — It chooses the highest-priority incomplete item
3. **Implement** — It writes code for that one feature
4. **Verify** — It runs your tests (`pnpm typecheck`, `pnpm test`)
5. **Update** — It marks the item complete and logs progress
6. **Commit** — It commits the changes
7. **Repeat** — Until all items pass or it signals completion

### Learn More

- [Matt Pocock's thread](https://x.com/mattpocockuk/status/2007924876548637089)
- [Ship working code while you sleep (video)](https://www.youtube.com/watch?v=_IK18goX4X8)
- [11 Tips For AI Coding With Ralph Wiggum](https://www.aihero.dev/tips-for-ai-coding-with-ralph-wiggum)
- [Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)

---

## Requirements

- **Windows** with **PowerShell 7+** (recommended)
  - Download: [PowerShell 7+ for Windows](https://github.com/PowerShell/PowerShell/releases)
- **GitHub Copilot CLI** installed and authenticated
  - Install: `winget install GitHub.Copilot` or `npm i -g @github/copilot`
- Any required API keys/tokens (if needed by your configuration)

---

## Installation

### Install as a PowerShell Module (Recommended)

```powershell
# 1. Clone the repository
git clone https://github.com/Snellingen/posh-ralph.git
cd posh-ralph

# 2. Verify PowerShell version (must be 7.0+)
$PSVersionTable.PSVersion

# 3. Install the module (per-user)
pwsh -File ./Install-RalphModule.ps1

# 4. Verify installation
Get-Command -Module PoshRalph
```

**Installation Options:**
- `-Force` — Overwrite an existing installation
- `-Scope AllUsers` — Install under $env:ProgramFiles (requires admin)
- `-ModuleVersion 1.3.0` — Override the version (defaults to the manifest value)

### Set Up Ralph in Your Project

After installing the module, set up Ralph in any project:

```powershell
# Navigate to your project
cd /path/to/your/project

# Set up Ralph project files
Setup-RalphProject
```

The `Setup-RalphProject` command creates:
- `prompts/default.txt` — Default prompt template
- `plans/prd.json` — Your work items (PRD)
- `plans/prd.schema.json` — JSON Schema for validation
- `progress.txt` — Progress log
- `RALPH-GETTING-STARTED.md` — Getting started guide
- `test-coverage-progress.txt` — Test coverage tracking

**Setup Options:**
- `-Force` — Overwrite existing files
- `-TargetPath <path>` — Set up in a specific directory

---

## Usage

### Start the Ralph Loop

```powershell
# Run with a prompt and PRD for 10 iterations
Invoke-RalphCopilot -PromptFile prompts/default.txt -PrdFile plans/prd.json -AllowProfile safe -Iterations 10

# Run with verbose output
Invoke-RalphCopilot -PromptFile prompts/default.txt -PrdFile plans/prd.json -AllowProfile safe -Iterations 10 -Verbose

# Use a custom model
Invoke-RalphCopilot -Model claude-opus-4.5 -PromptFile prompts/default.txt -PrdFile plans/prd.json -AllowProfile safe -Iterations 10
```

**Output:** Ralph displays the model and cost at startup:
```
Ralph Loop Configuration
=========================
Model:      claude-haiku-4.5
Cost:       0.33x
Iterations: 10
=========================
```
Cost is color-coded: **Green** (free), **Yellow** (0.33x), **White** (1.0x), **Red** (3.0x)

> **Note:** Copilot CLI only supports real-time streaming in interactive UI mode. When run from scripts, output appears when each iteration completes. You'll see "Invoking GitHub Copilot CLI..." while it's working.

### Single Test Run

```powershell
# Test with a single iteration
Invoke-Ralph -PromptFile prompts/default.txt -PrdFile plans/prd.json -AllowProfile safe

# Run with verbose output
Invoke-Ralph -PromptFile prompts/default.txt -AllowProfile safe -Verbose
```

### Show Help

```powershell
# Show help for the loop command
Get-Help Invoke-RalphCopilot -Full

# Show help for the single-run command
Get-Help Invoke-Ralph -Full
```

---

## Configuration

### Choose a Model

You can specify a model using the `-Model` parameter (recommended) or the `MODEL` environment variable as a fallback:

```powershell
# List all available models (with auto-complete support)
Invoke-RalphCopilot -ListModels

# Use a specific model with parameter (recommended - has auto-complete)
Invoke-RalphCopilot -Model claude-haiku-4.5 -PromptFile prompts/default.txt -PrdFile plans/prd.json -AllowProfile safe -Iterations 10

# Alternative: Use environment variable as fallback
$env:MODEL = "claude-opus-4.5"
Invoke-RalphCopilot -PromptFile prompts/default.txt -PrdFile plans/prd.json -AllowProfile safe -Iterations 10
```

**Available models** (relative cost):
- **Free**: `gpt-5-mini`, `gpt-4.1`
- **Fast/Cheap (0.33x)**: `claude-haiku-4.5`, `gpt-5.1-codex-mini`
- **Standard (1.0x)**: `claude-sonnet-4.5` (default), and most others
- **Premium (3.0x)**: `claude-opus-4.5`

**Update model list from copilot CLI:**

> **Note:** This command is only available when running from the repository directory.

```powershell
# Navigate to the posh-ralph repository
cd /path/to/posh-ralph

# Update the model list when new models are available
.\Update-ModelList.ps1

# Preview changes without applying
.\Update-ModelList.ps1 -DryRun
```

### Define Your Work Items

Create `plans/prd.json` with your requirements:

```json
[
  {
    "category": "functional",
    "description": "User can send a message and see it in the conversation",
    "steps": ["Open chat", "Type message", "Click Send", "Verify it appears"],
    "passes": false
  }
]
```

| Field         | Description                                |
|---------------|--------------------------------------------|
| `category`    | `"functional"`, `"ui"`, or custom          |
| `description` | One-line summary                           |
| `steps`       | How to verify it works                     |
| `passes`      | `false` → `true` when complete             |

See the [`plans/`](plans/) folder for more examples.

### Use Custom Prompts

Prompts are required. Use any prompt file:

```powershell
Invoke-RalphCopilot -PromptFile prompts/my-prompt.txt -AllowProfile safe -Iterations 10
```

> **Note:** Custom prompts require `-AllowProfile` or `-AllowTools`.

---

## Command Reference

### `Invoke-RalphCopilot` — Looped Runner

Runs Copilot up to N iterations. Stops early on `<promise>COMPLETE</promise>`.

```powershell
Invoke-RalphCopilot [options] -Iterations <N>
```

**Options:**

| Option                   | Description                          | Default               |
|--------------------------|--------------------------------------|-----------------------|
| `-PromptFile <file>`     | Load prompt from file (required)     | —                     |
| `-PrdFile <file>`        | Optionally attach a PRD JSON file    | —                     |
| `-Skill <a[,b,...]>`     | Prepend skills from `skills/<name>/SKILL.md` | —              |
| `-AllowProfile <name>`   | Permission profile (see below)       | —                     |
| `-AllowTools <spec>`     | Allow specific tool (repeatable)     | —                     |
| `-DenyTools <spec>`      | Deny specific tool (repeatable)      | —                     |
| `-Model <model>`         | AI model to use                      | `claude-sonnet-4.5`   |
| `-Iterations <N>`        | Number of iterations (required)      | —                     |
| `-Verbose`               | Show verbose output                  | —                     |
| `-Help`                  | Show help                            | —                     |
| `-ListModels`            | List available models and costs      | —                     |

**Examples:**

```powershell
Invoke-RalphCopilot -PromptFile prompts/default.txt -PrdFile plans/prd.json -AllowProfile safe -Iterations 10

# Use a faster/cheaper model
Invoke-RalphCopilot -Model claude-haiku-4.5 -PromptFile prompts/default.txt -PrdFile plans/prd.json -AllowProfile safe -Iterations 10

# With verbose output
Invoke-RalphCopilot -PromptFile prompts/wp.txt -AllowProfile safe -Iterations 10 -Verbose

# Use a specific model
Invoke-RalphCopilot -Model claude-opus-4.5 -PromptFile prompts/default.txt -PrdFile plans/prd.json -AllowProfile safe -Iterations 10
```

### `Invoke-Ralph` — Single Run

Runs Copilot once. Great for testing.

```powershell
Invoke-Ralph [options]
```

**Options:**

Same as `Invoke-RalphCopilot` except no `-Iterations` parameter.

**Examples:**

```powershell
Invoke-Ralph -PromptFile prompts/default.txt -PrdFile plans/prd.json -AllowProfile safe

# Use a specific model
Invoke-Ralph -Model gpt-5-mini -PromptFile prompts/default.txt -PrdFile plans/prd.json -AllowProfile safe

# With verbose output
Invoke-Ralph -PromptFile prompts/wp.txt -AllowProfile locked -Verbose

# Use a specific model
Invoke-Ralph -Model claude-opus-4.5 -PromptFile prompts/default.txt -PrdFile plans/prd.json -AllowProfile safe
```

### `Setup-RalphProject` — Project Setup

Sets up Ralph in your project directory with all required files.

```powershell
Setup-RalphProject [-TargetPath <path>] [-Force]
```

**Options:**

| Option                | Description                                     | Default        |
|-----------------------|-------------------------------------------------|----------------|
| `-TargetPath <path>`  | Directory to set up (defaults to current)       | `.` (current)  |
| `-Force`              | Overwrite existing files                        | —              |

**Examples:**

```powershell
# Set up in current directory
Setup-RalphProject

# Set up in specific directory
Setup-RalphProject -TargetPath /path/to/project

# Overwrite existing files
Setup-RalphProject -Force
```

### Permission Profiles

| Profile  | Allows                                 | Use Case                     |
|----------|----------------------------------------|------------------------------|
| `locked` | `write` only                           | File edits, no shell         |
| `safe`   | `write`, `shell(pnpm:*)`, `shell(git:*)` | Normal dev workflow        |
| `dev`    | All tools                              | Broad shell access           |

**Always denied:** `shell(rm)`, `shell(git push)`

**Custom tools:** If you pass `-AllowTools`, it replaces the profile defaults:

```powershell
Invoke-RalphCopilot -PromptFile prompts/wp.txt -AllowTools write -AllowTools 'shell(composer:*)' -Iterations 10
```

### Environment Variables

| Variable | Description                                 | Default              |
|----------|---------------------------------------------|----------------------|
| `MODEL`  | Model to use (prefer `-Model` parameter)   | `claude-sonnet-4.5`  |

> **Note:** Using the `-Model` parameter is recommended over the environment variable as it provides auto-complete support for available models.

---

## Cross-Platform Note

If you have **PowerShell 7+** on Linux/macOS, you can use posh-ralph after installing the module:

```powershell
# Linux/macOS with PowerShell 7+
pwsh -File ./Install-RalphModule.ps1
Setup-RalphProject
Invoke-RalphCopilot -PromptFile prompts/default.txt -PrdFile plans/prd.json -AllowProfile safe -Iterations 10
```

> ⚠️ This path is **not tested** in this repo yet. Please open issues with findings.

---

## Differences from the Original

- **PowerShell-based CLI/runtime** instead of shell scripts
- **Windows-first** testing and guidance
- **PowerShell 7+ requirement** (no Windows PowerShell 5.1 support)
- Command names/flags are kept as close as possible to the original
- Uses PowerShell parameter syntax (`-ParameterName value`) instead of shell syntax (`--parameter value`)

---

## Project Structure

```
.
├── src/PoshRalph/             # PowerShell module
│   ├── PoshRalph.psd1         # Module manifest
│   ├── PoshRalph.psm1         # Module loader
│   ├── Public/                # Exported functions
│   └── Private/               # Internal helpers
├── plans/prd.json             # Your work items
├── prompts/default.txt        # Example prompt
├── progress.txt               # Running log
├── ralph.ps1                  # Looped runner (PowerShell)
├── ralph-once.ps1             # Single-run script (PowerShell)
├── Update-ModelList.ps1       # Update model list from copilot CLI
└── RALPH.md                   # Module install and project setup guide
```

---

## Install Copilot CLI

```powershell
# Check version
copilot --version

# Windows (winget)
winget install GitHub.Copilot

# Windows (npm)
npm i -g @github/copilot

# Upgrade (winget)
winget upgrade GitHub.Copilot

# Upgrade (npm)
npm update -g @github/copilot
```

For Linux/macOS:

```bash
# Homebrew
brew update && brew upgrade copilot

# npm
npm i -g @github/copilot
```

---

## Contributing

- Please open issues for gaps, bugs, or Linux/macOS experiences
- PRs welcome—prefer small, focused changes
- PowerShell code should follow standard conventions and use `CmdletBinding()` for functions

---

## Skills (`-Skill`)

[Skills](https://agentskills.io/home) let you prepend reusable instructions into the same attached context file.
Pass a comma-separated list:

- `-Skill wp-block-development` loads `skills/wp-block-development/SKILL.md`
- `-Skill aa,bb,cc` loads `skills/aa/SKILL.md`, `skills/bb/SKILL.md`, `skills/cc/SKILL.md`

Example:

```powershell
Invoke-RalphCopilot -PromptFile prompts/wordpress-plugin-agent.txt `
  -Skill wp-block-development,wp-cli `
  -PrdFile plans/prd.json `
  -AllowProfile safe `
  -Iterations 5
```

---

## Local Development

If you want to contribute to posh-ralph or test changes locally without installing the module:

```powershell
# Clone the repository
git clone https://github.com/Snellingen/posh-ralph.git
cd posh-ralph

# Verify PowerShell version (must be 7.0+)
$PSVersionTable.PSVersion

# Run directly using local scripts
.\ralph-once.ps1 -PromptFile prompts/default.txt -PrdFile plans/prd.json -AllowProfile safe

# Run multiple iterations
.\ralph.ps1 -PromptFile prompts/default.txt -PrdFile plans/prd.json -AllowProfile safe -Iterations 10

# Show help
.\ralph.ps1 -Help
.\ralph-once.ps1 -Help
```

---

## License

MIT — see [LICENSE](LICENSE).
