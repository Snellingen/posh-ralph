#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 || -z "${1:-}" ]]; then
  echo "Usage: $0 <iterations>"
  exit 1
fi

if ! [[ "$1" =~ ^[0-9]+$ ]] || [[ "$1" -lt 1 ]]; then
  echo "Error: <iterations> must be a positive integer"
  exit 1
fi

iterations="$1"

# Default model if not provided
MODEL="${MODEL:-gpt-5.2}"

# Ensure progress file exists so @file expansion doesn't fail.
: > test-coverage-progress.txt

PROMPT=$(
  cat <<'PROMPT'
You are improving test coverage in the current repo.

Use this file as your running log (append only):
- test-coverage-progress.txt

WHAT MAKES A GREAT TEST:
- A great test covers behavior users depend on.
- It validates real workflows, not implementation details.
- It catches regressions before users do.
- Do NOT write tests just to increase coverage.
- Use coverage only to find untested, user-facing behavior.
- If uncovered code is not worth testing (boilerplate, unreachable branches, internal plumbing),
  prefer adding /* v8 ignore next */ or /* v8 ignore start */ instead of low-value tests.

PROCESS:
1. Run `pnpm coverage` to see which files have low coverage.
2. Read the uncovered lines and identify the most important USER-FACING feature that lacks tests.
   Prioritize: error handling users will hit, CLI commands, git operations, file parsing.
   Deprioritize: internal utilities, edge cases users won't encounter, boilerplate.
3. Write ONE meaningful test that validates the feature works correctly for users.
4. Run `pnpm coverage` again. Coverage should increase as a side effect of testing real behavior.
5. Commit with message: test(<file>): <describe the user behavior being tested>
6. Append super-concise notes to test-coverage-progress.txt: what you tested, coverage %, any learnings.

ONLY WRITE ONE TEST PER ITERATION.
If statement coverage reaches 100%, output <promise>COMPLETE</promise>.
PROMPT
)

for ((i=1; i<=iterations; i++)); do
  echo -e "\nIteration $i"
  echo "------------------------------------"

  # Copilot may return non-zero (auth/rate limit/etc). Don't let that kill the loop.
  set +e
  result=$(
    copilot --model "$MODEL" \
      -p "@test-coverage-progress.txt $PROMPT" \
      --allow-all-tools \
      --allow-tool 'write' \
      --allow-tool 'shell(pnpm)' \
      --allow-tool 'shell(git)' \
      --deny-tool 'shell(rm)' \
      --deny-tool 'shell(git push)' \
      2>&1
  )
  status=$?
  set -e

  echo "$result"

  if [[ $status -ne 0 ]]; then
    echo "Copilot exited with status $status; continuing to next iteration."
    continue
  fi

  if [[ "$result" == *"<promise>COMPLETE</promise>"* ]]; then
    echo "100% coverage reached, exiting."
    if command -v tt >/dev/null 2>&1; then
      tt notify "100% coverage after $i iterations"
    fi
    exit 0
  fi
done

echo "Finished $iterations iterations without receiving the completion signal."
