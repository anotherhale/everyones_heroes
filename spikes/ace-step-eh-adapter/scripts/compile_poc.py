#!/usr/bin/env python3
"""Compile POC timelines → ACE-Step request JSON (inspiration LM off).

Usage:
  python scripts/compile_poc.py
  python scripts/compile_poc.py --mode conventional --out-dir ./out

Does not call ACE-Step or download weights. Emits GenerationParams-shaped JSON
ready for a later manual /release_task handoff when a GPU host is available.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "src"))

from ace_step_eh_adapter.compiler import compile_timeline, repaint_window_for_phase
from ace_step_eh_adapter.fixtures_io import load_poc_pair
from ace_step_eh_adapter.models import CompilerMode


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--mode",
        choices=[m.value for m in CompilerMode],
        default=CompilerMode.EH_TAGS.value,
        help="Phase tag compiler backend (default: eh_tags)",
    )
    parser.add_argument(
        "--out-dir",
        type=Path,
        default=ROOT / "out",
        help="Directory for compiled JSON artifacts",
    )
    parser.add_argument("--seed", type=int, default=42)
    args = parser.parse_args()

    mode = CompilerMode(args.mode)
    story, timeline_a, timeline_b = load_poc_pair()
    args.out_dir.mkdir(parents=True, exist_ok=True)

    results = {}
    for timeline in (timeline_a, timeline_b):
        request = compile_timeline(
            story, timeline, mode=mode, seed_value=args.seed
        )
        assert request.inspiration_lm_off
        assert request.params.use_llm_inspiration is False
        assert request.params.thinking is False

        out_path = args.out_dir / f"{timeline.timeline_id}__{mode.value}.json"
        payload = request.to_dict()
        # Include a sample repaint mapping for Breakthrough when present.
        try:
            payload["example_repaint_breakthrough"] = repaint_window_for_phase(
                request, "Breakthrough"
            )
        except KeyError:
            pass

        out_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
        results[timeline.timeline_id] = {
            "path": str(out_path),
            "duration": request.params.duration,
            "caption_chars": len(request.params.caption),
            "lyrics_chars": len(request.params.lyrics),
            "phase_windows": len(request.phase_windows),
        }
        print(f"wrote {out_path}")

    # Diff summary proving timeline change → plan change
    a = compile_timeline(story, timeline_a, mode=mode, seed_value=args.seed)
    b = compile_timeline(story, timeline_b, mode=mode, seed_value=args.seed)
    diff = {
        "same_story_id": a.story_id == b.story_id == story.story_id,
        "same_seed": a.params.seed == b.params.seed,
        "same_bpm": a.params.bpm == b.params.bpm,
        "same_model_hint": a.params.model_hint == b.params.model_hint,
        "inspiration_lm_off": a.inspiration_lm_off and b.inspiration_lm_off,
        "caption_differs": a.params.caption != b.params.caption,
        "lyrics_differ": a.params.lyrics != b.params.lyrics,
        "phase_windows_differ": a.phase_windows != b.phase_windows,
        "duration_same": a.params.duration == b.params.duration,
    }
    summary_path = args.out_dir / f"poc_diff_summary__{mode.value}.json"
    summary_path.write_text(
        json.dumps({"results": results, "invariant_checks": diff}, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"wrote {summary_path}")
    print(json.dumps(diff, indent=2))

    if not (
        diff["same_story_id"]
        and diff["inspiration_lm_off"]
        and diff["caption_differs"]
        and diff["lyrics_differ"]
        and diff["phase_windows_differ"]
    ):
        print("POC invariant FAILED", file=sys.stderr)
        return 1
    print("POC invariant OK: same story, inspiration LM off, timelines change the plan")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
