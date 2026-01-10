# Sample prompts

This folder contains example prompt files to use with `--prompt`.

## Usage

Looped runner:

```bash
./ralph.sh --prompt prompts/default.txt --allow-profile dev 10
```

Single run:

```bash
./ralph-once.sh --prompt prompts/default.txt --allow-profile dev
```

## Examples (per prompt)

```bash
./ralph.sh --prompt prompts/default.txt --prd plans/prd.json --allow-profile safe 10
```

```bash
./ralph.sh --prompt prompts/safe-write-only.txt --allow-profile locked 10
```

```bash
./ralph.sh --prompt prompts/wordpress-plugin-agent.txt --prd plans/prd.json --allow-profile safe 10
```

```bash
./ralph.sh --prompt prompts/pest-coverage.txt --allow-profile safe 10
```

## Tool permissions

Tool permissions are controlled by the scripts via flags (not by prompt file content).

Examples:

```bash
./ralph-once.sh --prompt prompts/safe-write-only.txt \
  --allow-profile locked
```

```bash
./ralph.sh --prompt prompts/default.txt --allow-profile dev \
  --deny-tools 'shell(git push)' \
  10
```
