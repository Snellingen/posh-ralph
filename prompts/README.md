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
