param(
    [Parameter(Mandatory = $false)]
    [string]$TargetPath = '.',

    [switch]$Force
)

# If the module is installed, delegate to its function so the script works anywhere.
try {
  Import-Module PoshRalph -ErrorAction Stop
  Setup-RalphProject @PSBoundParameters
  return
}
catch {
  # Fall back to the local implementation below.
}

function Set-RalphFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$Content,
        [switch]$ForceWrite
    )

    $directory = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }

    if ((-not $ForceWrite) -and (Test-Path -LiteralPath $Path -PathType Leaf)) {
        Write-Host "Skip existing: $Path" -ForegroundColor Yellow
        return
    }

    $Content | Set-Content -LiteralPath $Path -Encoding UTF8
    Write-Host "Wrote: $Path" -ForegroundColor Green
}

$resolvedRoot = Resolve-Path -LiteralPath $TargetPath -ErrorAction SilentlyContinue
if (-not $resolvedRoot) {
    New-Item -ItemType Directory -Path $TargetPath -Force | Out-Null
    $resolvedRoot = Resolve-Path -LiteralPath $TargetPath
}

$root = $resolvedRoot.Path
Write-Host "Setting up Ralph in: $root" -ForegroundColor Cyan

$promptPath = Join-Path $root 'prompts/default.txt'
$planPath = Join-Path $root 'plans/prd.json'
$planSchemaPath = Join-Path $root 'plans/prd.schema.json'
$progressPath = Join-Path $root 'progress.txt'
$coveragePath = Join-Path $root 'test-coverage-progress.txt'
$gettingStartedPath = Join-Path $root 'RALPH-GETTING-STARTED.md'

$defaultPrompt = @'
Work in the current repo using the provided context files:
- PRD JSON (path passed via -PrdFile)
- progress.txt
- test-coverage-progress.txt

Process for EACH iteration:
1) Pick the highest-priority incomplete item from the PRD (your judgment).
2) Implement only that item; avoid scope creep.
3) Run tests with YOUR command (replace this line with your real test command, e.g., pnpm test or pytest).
4) If you have coverage tooling, note the result in test-coverage-progress.txt (coverage %, area, notes).
5) Update the PRD item you completed (set passes to true and adjust steps if needed).
6) Append a short note to progress.txt about what changed and any follow-ups.
7) Make a git commit for the completed item.

Rules:
- Keep outputs concise and actionable.
- Do not assume paths; use the provided arguments for PRD and prompts.
- If PRD looks complete, output <promise>COMPLETE</promise>.
'@

$defaultPlan = @'
[
  {
    "category": "functional",
    "description": "User can send a message and see it appear",
    "steps": [
      "Open the chat app and navigate to a conversation",
      "Type a message",
      "Send it",
      "Verify it appears in the thread"
    ],
    "passes": false
  }
]
'@

$defaultPlanSchema = @'
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "Ralph PRD",
  "type": "array",
  "items": {
    "type": "object",
    "required": ["category", "description", "steps", "passes"],
    "additionalProperties": false,
    "properties": {
      "category": {
        "type": "string",
        "description": "Grouping, e.g. functional, ui, security, performance"
      },
      "description": {
        "type": "string",
        "description": "One-line requirement description"
      },
      "steps": {
        "type": "array",
        "items": { "type": "string" },
        "minItems": 1,
        "description": "Verification steps for the requirement"
      },
      "passes": {
        "type": "boolean",
        "description": "Whether the requirement is complete/validated"
      }
    }
  }
}
'@

$defaultProgress = @'
Not started
'@

$defaultCoverageProgress = @'
# Test coverage notes
# Replace this with your format, e.g.:
# 2026-01-21 | area: checkout flow | coverage: 78% -> 82% | note: added happy-path + decline tests
'@

$defaultGettingStarted = @'
# Ralph: Getting Started

## Files created
- prompts/default.txt
- plans/prd.json
- plans/prd.schema.json
- progress.txt
- test-coverage-progress.txt
- skills/ (place SKILL.md files here if you use skills)

## Run Ralph
From the repo root:

```
pwsh -Command "Import-Module PoshRalph; Invoke-RalphCopilot -PromptFile 'prompts/default.txt' -PrdFile 'plans/prd.json' -AllowProfile safe"
```

Notes:
- Ensure GitHub Copilot CLI is installed and on PATH (`copilot --help`).
- Skills are loaded from ./skills/<name>/SKILL.md when you pass -Skills <name> to Invoke-RalphCopilot.
- Edit prompts and PRD to reflect your project; set `passes` to false until verified.
- PRD schema lives at plans/prd.schema.json (JSON Schema, draft-07). Validate PRDs with: `pwsh -c "Get-Content plans/prd.json -Raw | ConvertFrom-Json | Out-Null"` or your preferred JSON schema tool.
- Update test-coverage-progress.txt after each test run with coverage tool of your choice.
'@

Set-RalphFile -Path $promptPath -Content $defaultPrompt -ForceWrite:$Force
Set-RalphFile -Path $planPath -Content $defaultPlan -ForceWrite:$Force
Set-RalphFile -Path $planSchemaPath -Content $defaultPlanSchema -ForceWrite:$Force
Set-RalphFile -Path $progressPath -Content $defaultProgress -ForceWrite:$Force
Set-RalphFile -Path $coveragePath -Content $defaultCoverageProgress -ForceWrite:$Force
Set-RalphFile -Path $gettingStartedPath -Content $defaultGettingStarted -ForceWrite:$Force

Write-Host "Setup complete. Run Invoke-RalphCopilot with your prompt and PRD." -ForegroundColor Cyan
