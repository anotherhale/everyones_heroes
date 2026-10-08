#!/usr/bin/env bash
# Phase 2 ACE-Step EH Narrative Music POC experiment.
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
echo "GPU validation: $(command -v nvidia-smi >/dev/null && echo AVAILABLE || echo UNAVAILABLE)"

"$PYTHON" -m pytest "$POC_ROOT/tests" -q

"$PYTHON" "$POC_ROOT/src/phase2_experiment.py" \
  --acestep-root "$ACESTEP_ROOT" \
  --output-root "$POC_ROOT/output/phase-2" \
  "$@"

"$PYTHON" "$POC_ROOT/src/phase2_analyze.py" \
  --output-root "$POC_ROOT/output/phase-2"

echo "Phase 2 generation/analysis done. See $POC_ROOT/output/phase-2/"
