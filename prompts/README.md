# Sample prompts

This folder contains example prompt files to use with `-PromptFile`.

## Usage

Looped runner:

Runs multiple iterations (good for actually making progress on a PRD).

```powershell
Invoke-RalphCopilot -PromptFile prompts/default.txt -AllowProfile dev -Iterations 10
```

Single run:

Runs exactly one iteration (good for testing your tool permissions and prompt wording).

```powershell
Invoke-Ralph -PromptFile prompts/default.txt -AllowProfile dev
```

## Examples (per prompt)

Default prompt + PRD:
Runs the standard workflow: attach your PRD and let Ralph iterate safely (write + limited shell).

Credit: [Ship working code while you sleep (video)](https://www.youtube.com/watch?v=_IK18goX4X8)

```powershell
Invoke-RalphCopilot -PromptFile prompts/default.txt -PrdFile plans/prd.json -AllowProfile safe -Iterations 10
```

Write-only prompt:
Use this when you want Copilot to only edit files (no shell access).

```powershell
Invoke-RalphCopilot -PromptFile prompts/safe-write-only.txt -AllowProfile locked -Iterations 10
```

WordPress plugin agent:
Targets WordPress development workflows; attaches a PRD but keeps tool access constrained by the harness/profile.

```powershell
Invoke-RalphCopilot -PromptFile prompts/wordpress-plugin-agent.txt -PrdFile plans/prd.json -AllowProfile safe -Iterations 10
```

Pest coverage:
Iterates on adding ONE meaningful test per iteration; typically you don't need a PRD for this style of task.

Credits: https://gist.github.com/mpociot/914c1871e6faeb350d2fda09ecb2a18f

```powershell
Invoke-RalphCopilot -PromptFile prompts/pest-coverage.txt -AllowProfile safe -Iterations 10
```

## Tool permissions

Tool permissions are controlled by the scripts via flags (not by prompt file content).

Examples:

Single-run, write-only:
Useful when you want to validate the prompt behavior without letting the agent run any shell commands.

```powershell
Invoke-Ralph -PromptFile prompts/safe-write-only.txt -AllowProfile locked
```

Looped run with explicit deny:
Allows everything in the `dev` profile, but still blocks a dangerous command.

```powershell
Invoke-RalphCopilot -PromptFile prompts/default.txt -AllowProfile dev -DenyTools 'shell(git push)' -Iterations 10
```
