#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE
Usage:
  ./test/run-prompts.sh

What it does:
  - Finds all *.txt prompts in ./prompts
  - Creates a git worktree per prompt
  - Runs ./ralph-once.sh with that prompt inside the worktree
  - Logs stdout/stderr to ./test/log/<timestamp>/
  - Removes the worktree and its temp branch

Environment variables:
  MAIN_BRANCH   Base branch for worktrees (default: main)
  MODEL         Copilot model (default: gpt-5.2)
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "Error: must run inside a git repository" >&2
  exit 1
}

MAIN_BRANCH="${MAIN_BRANCH:-main}"
MODEL="${MODEL:-gpt-5.2}"

# Prefer logging into the main-branch worktree if it exists; otherwise use current worktree.
LOG_ROOT="$ROOT"
if git -C "$ROOT" worktree list --porcelain | awk -v b="refs/heads/$MAIN_BRANCH" '
    $1=="worktree"{path=$2}
    $1=="branch" && $2==b{print path; exit}
  ' >/tmp/ralph-main-worktree-path.$$ 2>/dev/null; then
  MAIN_WT_PATH="$(cat /tmp/ralph-main-worktree-path.$$ || true)"
  rm -f /tmp/ralph-main-worktree-path.$$ || true
  if [[ -n "$MAIN_WT_PATH" ]]; then
    LOG_ROOT="$MAIN_WT_PATH"
  fi
fi

TS="$(date -u +%Y%m%dT%H%M%SZ)"
RUN_LOG_DIR="$LOG_ROOT/test/log/$TS"
mkdir -p "$RUN_LOG_DIR"

PROMPTS_DIR="$ROOT/prompts"
if [[ ! -d "$PROMPTS_DIR" ]]; then
  echo "Error: prompts folder not found at: $PROMPTS_DIR" >&2
  exit 1
fi

mapfile -t PROMPT_FILES < <(find "$PROMPTS_DIR" -maxdepth 1 -type f -name "*.txt" | sort)
if [[ ${#PROMPT_FILES[@]} -eq 0 ]]; then
  echo "Error: no prompt files found in $PROMPTS_DIR" >&2
  exit 1
fi

render_progress() {
  local current="$1"
  local total="$2"
  local label="$3"
  local width=28
  local filled=$(( current * width / total ))
  local empty=$(( width - filled ))
  local bar_filled bar_empty

  printf -v bar_filled "%*s" "$filled" ""
  bar_filled=${bar_filled// /#}
  printf -v bar_empty "%*s" "$empty" ""
  bar_empty=${bar_empty// /-}

  printf "\r[%s%s] %d/%d %s" "$bar_filled" "$bar_empty" "$current" "$total" "$label" >&2
}

echo "Logging to: $RUN_LOG_DIR"

echo "prompt\tstatus\tworktree" >"$RUN_LOG_DIR/summary.tsv"

run_one_prompt() {
  local prompt_path="$1"
  local prompt_file
  local prompt_name
  local prd_file
  local prd_src
  local wt_dir
  local branch
  local log_file

  prompt_file="$(basename "$prompt_path")"
  prompt_name="${prompt_file%.txt}"
  prd_file="plans/prd-${prompt_name}.json"
  prd_src="$ROOT/$prd_file"

  wt_dir="$ROOT/test/worktrees/${TS}-${prompt_name}"
  branch="ralph-test/${TS}-${prompt_name}"
  log_file="$RUN_LOG_DIR/${prompt_name}.log"

  mkdir -p "$(dirname "$wt_dir")"

  # Prefer per-prompt PRDs, but fall back to the default PRD when none exists.
  if [[ ! -r "$prd_src" ]]; then
    prd_file="plans/prd.json"
    prd_src="$ROOT/$prd_file"
    if [[ ! -r "$prd_src" ]]; then
      echo "Error: default PRD file not readable: $prd_file" | tee -a "$log_file" >&2
      echo "Hint: create it at: $prd_src" | tee -a "$log_file" >&2
      echo -e "${prompt_file}\tSKIP(missing-prd)\t-" >>"$RUN_LOG_DIR/summary.tsv"
      return 0
    fi
  fi

  # Ensure cleanup even if the copilot run fails.
  cleanup() {
    set +e
    git -C "$ROOT" worktree remove --force "$wt_dir" >/dev/null 2>&1 || true
    git -C "$ROOT" branch -D "$branch" >/dev/null 2>&1 || true
    git -C "$ROOT" worktree prune >/dev/null 2>&1 || true
  }
  trap cleanup RETURN

  echo "==> [$prompt_name] creating worktree: $wt_dir" | tee -a "$log_file"
  git -C "$ROOT" worktree add -b "$branch" "$wt_dir" "$MAIN_BRANCH" >>"$log_file" 2>&1

  pushd "$wt_dir" >/dev/null

  # Use the current working tree versions of prompts and runner scripts so tests
  # reflect local changes even if they aren't committed yet.
  mkdir -p prompts
  cp "$ROOT/prompts/$prompt_file" "prompts/$prompt_file"
  cp "$ROOT/ralph-once.sh" ./ralph-once.sh
  chmod +x ./ralph-once.sh

  # Prompt-specific tool policy (kept in the runner, not in prompt files).
  # Feel free to tweak these mappings as you add more prompts.
  declare -a args
  mkdir -p "$(dirname "$prd_file")"
  cp "$prd_src" "$prd_file"

  args=("--prompt" "prompts/$prompt_file" "--prd" "$prd_file")

  case "$prompt_file" in
    wordpress-plugin-agent.txt)
      args+=("--allow-profile" "safe")
      args+=("--allow-tools" "write")
      args+=("--allow-tools" "shell(git)")
      args+=("--allow-tools" "shell(npx)")
      args+=("--allow-tools" "shell(composer)")
      args+=("--allow-tools" "shell(npm)")
      ;;
    safe-write-only.txt)
      args+=("--allow-profile" "locked")
      ;;
    *)
      # Default prompt expects pnpm + git checks; safe profile already allows those.
      args+=("--allow-profile" "safe")
      ;;
  esac

  echo "==> [$prompt_name] running ralph-once.sh ${args[*]}" | tee -a "$log_file"

  set +e
  MODEL="$MODEL" ./ralph-once.sh "${args[@]}" >>"$log_file" 2>&1
  local status=$?
  set -e

  # Basic expectations for certain prompts.
  if [[ "$prompt_file" == "wordpress-plugin-agent.txt" ]]; then
    if ! grep -qiE "wp-env start|composer lint|composer test" "$log_file"; then
      echo "[ASSERT] Missing expected WordPress checks in output" | tee -a "$log_file" >&2
      status=2
    fi
    if grep -qiE "\bpnpm\b" "$log_file"; then
      echo "[ASSERT] Unexpected pnpm mention in output" | tee -a "$log_file" >&2
      status=2
    fi
  fi

  popd >/dev/null

  if [[ $status -eq 0 ]]; then
    echo -e "${prompt_file}\tPASS\t$wt_dir" >>"$RUN_LOG_DIR/summary.tsv"
  else
    echo -e "${prompt_file}\tFAIL($status)\t$wt_dir" >>"$RUN_LOG_DIR/summary.tsv"
  fi

  return 0
}

total_prompts=${#PROMPT_FILES[@]}
current_prompt=0

for p in "${PROMPT_FILES[@]}"; do
  current_prompt=$((current_prompt + 1))
  render_progress "$current_prompt" "$total_prompts" "$(basename "$p")"
  run_one_prompt "$p" || true
done

printf "\n" >&2

echo "Done. Summary: $RUN_LOG_DIR/summary.tsv"
