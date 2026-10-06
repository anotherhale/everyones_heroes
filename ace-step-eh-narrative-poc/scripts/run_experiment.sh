#!/usr/bin/env bash
# Run the ACE-Step EH Narrative Music POC experiment.
set -euo pipefail

POC_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ACESTEP_ROOT="${ACESTEP_ROOT:-/home/ubuntu/ai-poc/ACE-Step-1.5}"
export ACESTEP_ROOT
export ACESTEP_PROJECT_ROOT="${ACESTEP_PROJECT_ROOT:-$ACESTEP_ROOT}"
export ACESTEP_CHECKPOINTS_DIR="${ACESTEP_CHECKPOINTS_DIR:-$ACESTEP_ROOT/checkpoints}"
export ACESTEP_INIT_LLM=false

cd "$POC_ROOT"

PYTHON="${PYTHON:-}"
if [[ -z "$PYTHON" ]]; then
  if [[ -x "$ACESTEP_ROOT/.venv/bin/python" ]]; then
    PYTHON="$ACESTEP_ROOT/.venv/bin/python"
  else
    PYTHON="python3"
  fi
fi

echo "POC_ROOT=$POC_ROOT"
echo "ACESTEP_ROOT=$ACESTEP_ROOT"
echo "PYTHON=$PYTHON"
echo "ACESTEP_INIT_LLM=$ACESTEP_INIT_LLM"

# Adapter unit tests first (no model required).
"$PYTHON" -m pytest "$POC_ROOT/tests" -q

# Experiment (pass-through args, e.g. --dry-run)
"$PYTHON" "$POC_ROOT/src/experiment.py" \
  --acestep-root "$ACESTEP_ROOT" \
  --skip-caption-only-extra-seeds \
  "$@"

"$PYTHON" "$POC_ROOT/src/compare.py" --output-root "$POC_ROOT/output"

echo "Done. See $POC_ROOT/output/"
