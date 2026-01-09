# Ralph (Copilot CLI runner)

> Let AI implement your features while you sleep.

Ralph runs **GitHub Copilot CLI** in a loop, implementing one feature at a time until your PRD is complete.

[Quick Start](#quick-start) · [How It Works](#how-it-works) · [Configuration](#configuration) · [Command Reference](#command-reference) · [Demo](#demo)


---

## Quick Start

```bash
# Clone and enter the repo
git clone https://github.com/soderlind/ralph
cd ralph

# Add your work items to plans/prd.json

# Test with a single run
./ralph-once.sh

# Run multiple iterations
./ralph.sh 10
```

Check `progress.txt` for a log of what was done.

---

## How It Works

Ralph implements the ["Ralph Wiggum" technique](https://www.humanlayer.dev/blog/brief-history-of-ralph):

1. **Read** — Copilot reads your PRD and progress file
2. **Pick** — It chooses the highest-priority incomplete item
3. **Implement** — It writes code for that one feature
4. **Verify** — It runs your tests (`pnpm typecheck`, `pnpm test`)
5. **Update** — It marks the item complete and logs progress
6. **Commit** — It commits the changes
7. **Repeat** — Until all items pass or it signals completion


https://github.com/user-attachments/assets/28206ee1-8dad-4871-aef5-1a9f24625dba


### Learn More

- [Matt Pocock's thread](https://x.com/mattpocockuk/status/2007924876548637089)
- [Ship working code while you sleep (video)](https://www.youtube.com/watch?v=_IK18goX4X8)
- [11 Tips For AI Coding With Ralph Wiggum](https://www.aihero.dev/tips-for-ai-coding-with-ralph-wiggum)

---

## Configuration

### Choose a Model

Set the `MODEL` environment variable (default: `gpt-5.2`):

```bash
MODEL=claude-opus-4.5 ./ralph.sh 10
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

### Use Custom Prompts

The default prompt is `prompts/default.txt`. Use a different one:

```bash
./ralph.sh --prompt prompts/my-prompt.txt --allow-profile safe 10
```

> **Note:** Custom prompts require `--allow-profile` or `--allow-tools`.

---

## Command Reference

### `ralph.sh` — Looped Runner

Runs Copilot up to N iterations. Stops early on `<promise>COMPLETE</promise>`.

```bash
./ralph.sh [options] <iterations>
```

**Examples:**

```bash
./ralph.sh 10                                    # Basic run
./ralph.sh --prompt prompts/wp.txt --allow-profile safe 10  # Custom prompt
MODEL=claude-opus-4.5 ./ralph.sh 10              # Different model
```

### `ralph-once.sh` — Single Run

Runs Copilot once. Great for testing.

```bash
./ralph-once.sh [options]
```

**Examples:**

```bash
./ralph-once.sh                                  # Basic run
./ralph-once.sh --prompt prompts/wp.txt --allow-profile locked
MODEL=claude-opus-4.5 ./ralph-once.sh
```

### Options

| Option                   | Description                          | Default               |
|--------------------------|--------------------------------------|-----------------------|
| `--prompt <file>`        | Load prompt from file                | `prompts/default.txt` |
| `--prd <file>`           | Use specific PRD JSON                | `plans/prd.json`      |
| `--allow-profile <name>` | Permission profile (see below)       | —                     |
| `--allow-tools <spec>`   | Allow specific tool (repeatable)     | —                     |
| `--deny-tools <spec>`    | Deny specific tool (repeatable)      | —                     |
| `-h, --help`             | Show help                            | —                     |

**Environment:**

| Variable | Description        | Default   |
|----------|--------------------|-----------|
| `MODEL`  | Model to use       | `gpt-5.2` |

### Permission Profiles

| Profile  | Allows                                 | Use Case                     |
|----------|----------------------------------------|------------------------------|
| `locked` | `write` only                           | File edits, no shell         |
| `safe`   | `write`, `shell(pnpm)`, `shell(git)`   | Normal dev workflow          |
| `dev`    | All tools                              | Broad shell access           |

**Always denied:** `shell(rm)`, `shell(git push)`

**Custom tools:** If you pass `--allow-tools`, it replaces the profile defaults:

```bash
./ralph.sh --prompt prompts/wp.txt --allow-tools write --allow-tools 'shell(composer)' 10
```

---

## Demo

Try Ralph in a safe sandbox:

```bash
# Setup
git clone https://github.com/soderlind/ralph && cd ralph
git worktree add ../ralph-demo -b ralph-demo
cd ../ralph-demo

# Run
./ralph-once.sh          # Test once
./ralph.sh 10            # Run 10 iterations

# Inspect
git log --oneline -20
cat progress.txt

# Cleanup
cd .. && git worktree remove ralph-demo && git branch -D ralph-demo
```

---

## Project Structure

```
.
├── plans/prd.json        # Your work items
├── prompts/default.txt   # Default prompt
├── progress.txt          # Running log
├── ralph.sh              # Looped runner
├── ralph-once.sh         # Single-run script
└── test/run-prompts.sh   # Test harness
```

---

## Install Copilot CLI

```bash
# Check version
copilot --version

# Homebrew
brew update && brew upgrade copilot

# npm
npm i -g @github/copilot

# Windows
winget upgrade GitHub.Copilot
```

---

## Testing Prompts

Run all prompts in isolated worktrees:

```bash
./test/run-prompts.sh
```

Logs: `test/log/`

---

## Credits

Prompt technique: [Matt Pocock](https://github.com/mattpocock)

## License

MIT — see [LICENSE](LICENSE).
