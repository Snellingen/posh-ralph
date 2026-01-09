# Plans

This folder contains the PRD (Product Requirements Document) that Ralph uses to guide the AI agent.

## Files

| File | Purpose |
|------|---------|
| `prd.json` | Default PRD — your work items |
| `prd-<name>.json` | Optional per-prompt PRDs |

## `prd.json` Format

A JSON array of work items:

```json
[
  {
    "category": "functional",
    "description": "User can send a message",
    "steps": ["Open chat", "Type message", "Click Send", "Verify it appears"],
    "passes": false
  }
]
```

| Field | Description |
|-------|-------------|
| `category` | `"functional"`, `"ui"`, or custom |
| `description` | One-line requirement |
| `steps` | How to verify it works |
| `passes` | `false` → `true` when complete |

## Best Practices

- **Keep items small** — one feature per agent iteration
- **Be specific** — clear acceptance criteria help the agent
- **Start with `passes: false`** — the agent flips it to `true`
- **Order by priority** — agent picks from the top

## Per-Prompt PRDs

Use `--prd` to specify a different PRD file:

```bash
./ralph.sh --prd plans/prd-wordpress.json --prompt prompts/wp.txt --allow-profile safe 10
```

## Example Only

The included `prd.json` is a template (chat-app stories). Replace with your own requirements.
