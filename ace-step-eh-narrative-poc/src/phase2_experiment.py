#!/usr/bin/env python3
"""Phase 2 controlled experiment runner.

Compares three adapter strategies on Phase 2 structural timelines:
  - narrative_tags
  - song_tags
  - caption_only

Inspiration LM remains OFF. Phase 1 outputs are never overwritten.
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional

POC_ROOT = Path(__file__).resolve().parents[1]
SRC_ROOT = Path(__file__).resolve().parent
if str(SRC_ROOT) not in sys.path:
    sys.path.insert(0, str(SRC_ROOT))

from ace_step_adapter import AceStepNarrativeAdapter, SectionTagStrategy  # noqa: E402
from experiment import (  # noqa: E402
    AceStepRuntime,
    DEFAULT_ACESTEP_ROOT,
    DEFAULT_SEEDS,
    _git_commit,
    _hardware_info,
    _utc_now,
    _write_json,
    run_one,
)
from narrative_music import (  # noqa: E402
    load_creative_direction,
    load_story,
    load_timeline,
)

PHASE2_STRATEGIES = (
    SectionTagStrategy.NARRATIVE_TAGS,
    SectionTagStrategy.SONG_TAGS,
    SectionTagStrategy.CAPTION_ONLY,
)


def compile_phase2_pair(
    *,
    strategy: SectionTagStrategy,
    seed: int,
) -> Dict[str, Any]:
    story = load_story(POC_ROOT / "inputs" / "story.txt")
    direction = load_creative_direction(POC_ROOT / "inputs" / "creative_direction.json")
    timeline_a = load_timeline(POC_ROOT / "inputs" / "phase2_timeline_a.json")
    timeline_b = load_timeline(POC_ROOT / "inputs" / "phase2_timeline_b.json")
    adapter = AceStepNarrativeAdapter(
        section_tag_strategy=strategy,
        disable_inspiration_lm=True,
    )
    req_a = adapter.compile(story, direction, timeline_a, seed=seed)
    req_b = adapter.compile(story, direction, timeline_b, seed=seed)
    return {
        "story": story.text,
        "direction": direction.to_dict(),
        "timeline_a": timeline_a.to_dict(),
        "timeline_b": timeline_b.to_dict(),
        "request_a": req_a.to_dict(),
        "request_b": req_b.to_dict(),
        "params_a": req_a.generation_params_dict(),
        "params_b": req_b.generation_params_dict(),
    }


def expected_phase_windows(timeline: Dict[str, Any], duration: float) -> List[Dict[str, Any]]:
    segments = timeline.get("segments") or []
    native = sum(float(s.get("duration_seconds", 0)) for s in segments) or 1.0
    scale = float(duration) / native
    t = 0.0
    windows = []
    for seg in segments:
        dur = float(seg["duration_seconds"]) * scale
        start = t
        end = t + dur
        windows.append(
            {
                "role": seg["role"],
                "narrative_intent": seg.get("narrative_intent"),
                "energy": seg.get("energy"),
                "start_s": round(start, 3),
                "end_s": round(end, 3),
                "start_pct": round(100.0 * start / duration, 2),
                "end_pct": round(100.0 * end / duration, 2),
            }
        )
        t = end
    return windows


def main(argv: Optional[List[str]] = None) -> int:
    parser = argparse.ArgumentParser(description="Phase 2 ACE-Step narrative music experiment")
    parser.add_argument("--acestep-root", type=Path, default=DEFAULT_ACESTEP_ROOT)
    parser.add_argument("--dit-model", default="acestep-v15-turbo")
    parser.add_argument("--seeds", default=",".join(str(s) for s in DEFAULT_SEEDS))
    parser.add_argument(
        "--strategies",
        default="narrative_tags,song_tags,caption_only",
        help="Comma-separated Phase 2 strategies",
    )
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument(
        "--output-root",
        type=Path,
        default=POC_ROOT / "output" / "phase-2",
    )
    parser.add_argument(
        "--skip-caption-only-extra-seeds",
        action="store_true",
        help="For caption_only, run only the first seed (CPU time control)",
    )
    args = parser.parse_args(argv)

    seeds = [int(x.strip()) for x in args.seeds.split(",") if x.strip()]
    strategies = [
        SectionTagStrategy(x.strip())
        for x in args.strategies.split(",")
        if x.strip()
    ]

    output_root: Path = args.output_root
    output_root.mkdir(parents=True, exist_ok=True)

    # Safety: never write into phase-1 baseline directory.
    if "phase-1" in output_root.parts:
        raise SystemExit("Refusing to write into phase-1 baseline directory")

    manifest: Dict[str, Any] = {
        "phase": 2,
        "started_at": _utc_now(),
        "acestep_root": str(args.acestep_root),
        "acestep_commit": _git_commit(args.acestep_root),
        "dit_model": args.dit_model,
        "seeds": seeds,
        "strategies": [s.value for s in strategies],
        "dry_run": args.dry_run,
        "hardware": _hardware_info(),
        "gpu_validation": "UNAVAILABLE"
        if not _hardware_info().get("cuda_available")
        else "AVAILABLE",
        "inspiration_lm": "OFF",
        "timelines": {
            "a": str(POC_ROOT / "inputs" / "phase2_timeline_a.json"),
            "b": str(POC_ROOT / "inputs" / "phase2_timeline_b.json"),
        },
        "results": [],
    }

    runtime: Optional[AceStepRuntime] = None
    if not args.dry_run:
        runtime = AceStepRuntime(args.acestep_root, dit_model=args.dit_model)
        runtime.initialize()

    for strategy in strategies:
        strategy_seeds = seeds
        if (
            args.skip_caption_only_extra_seeds
            and strategy == SectionTagStrategy.CAPTION_ONLY
            and seeds
        ):
            strategy_seeds = seeds[:1]
        for seed in strategy_seeds:
            compiled = compile_phase2_pair(strategy=strategy, seed=seed)
            pair_dir = output_root / f"strategy_{strategy.value}" / f"seed_{seed}"
            meta_a = run_one(
                timeline_key="timeline_a",
                request=compiled["request_a"],
                params=compiled["params_a"],
                out_dir=pair_dir / "timeline_a",
                acestep_root=args.acestep_root,
                dry_run=args.dry_run,
                dit_model=args.dit_model,
                runtime=runtime,
            )
            # Patch source file pointers to phase2 timelines in metadata.
            meta_a["source_files"] = {
                "story": str(POC_ROOT / "inputs" / "story.txt"),
                "creative_direction": str(
                    POC_ROOT / "inputs" / "creative_direction.json"
                ),
                "timeline_a": str(POC_ROOT / "inputs" / "phase2_timeline_a.json"),
                "timeline_b": str(POC_ROOT / "inputs" / "phase2_timeline_b.json"),
            }
            meta_a["expected_phase_windows"] = expected_phase_windows(
                compiled["timeline_a"], float(compiled["params_a"]["duration"])
            )
            _write_json(pair_dir / "timeline_a" / "generation-metadata.json", meta_a)

            meta_b = run_one(
                timeline_key="timeline_b",
                request=compiled["request_b"],
                params=compiled["params_b"],
                out_dir=pair_dir / "timeline_b",
                acestep_root=args.acestep_root,
                dry_run=args.dry_run,
                dit_model=args.dit_model,
                runtime=runtime,
            )
            meta_b["source_files"] = meta_a["source_files"]
            meta_b["expected_phase_windows"] = expected_phase_windows(
                compiled["timeline_b"], float(compiled["params_b"]["duration"])
            )
            _write_json(pair_dir / "timeline_b" / "generation-metadata.json", meta_b)

            manifest["results"].append(
                {
                    "strategy": strategy.value,
                    "seed": seed,
                    "timeline_a": meta_a,
                    "timeline_b": meta_b,
                }
            )
            _write_json(output_root / "run_manifest.json", manifest)

    manifest["finished_at"] = _utc_now()
    _write_json(output_root / "run_manifest.json", manifest)
    print(json.dumps({"status": "done", "manifest": str(output_root / "run_manifest.json")}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
