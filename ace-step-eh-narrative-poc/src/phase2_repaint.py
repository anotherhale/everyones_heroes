#!/usr/bin/env python3
"""Phase 2 repaint experiment: target Timeline B breakthrough window.

Uses a base text2music take (Timeline A or B) as src_audio, then repaints only
the breakthrough time window with Timeline B breakthrough intent.
"""

from __future__ import annotations

import argparse
import json
import shutil
import sys
from pathlib import Path
from typing import Any, Dict, Optional

POC_ROOT = Path(__file__).resolve().parents[1]
SRC_ROOT = Path(__file__).resolve().parent
if str(SRC_ROOT) not in sys.path:
    sys.path.insert(0, str(SRC_ROOT))

from ace_step_adapter import AceStepNarrativeAdapter, SectionTagStrategy  # noqa: E402
from experiment import (  # noqa: E402
    AceStepRuntime,
    DEFAULT_ACESTEP_ROOT,
    _git_commit,
    _hardware_info,
    _utc_now,
    _write_json,
)
from narrative_music import (  # noqa: E402
    load_creative_direction,
    load_story,
    load_timeline,
)
from phase2_experiment import expected_phase_windows  # noqa: E402


def _find_window(windows, role: str) -> Dict[str, Any]:
    for w in windows:
        if w["role"] == role:
            return w
    raise KeyError(role)


def main(argv: Optional[list[str]] = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--acestep-root", type=Path, default=DEFAULT_ACESTEP_ROOT)
    parser.add_argument("--dit-model", default="acestep-v15-turbo")
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument(
        "--base-audio",
        type=Path,
        default=None,
        help="Optional existing WAV to repaint; otherwise generate Timeline A base first",
    )
    parser.add_argument(
        "--output-root",
        type=Path,
        default=POC_ROOT / "output" / "phase-2" / "repaint",
    )
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--repaint-strength", type=float, default=0.5)
    parser.add_argument(
        "--duration",
        type=float,
        default=None,
        help="Optional shorter duration for CPU-memory-limited repaint proofs",
    )
    args = parser.parse_args(argv)

    out_root: Path = args.output_root
    out_root.mkdir(parents=True, exist_ok=True)
    if "phase-1" in out_root.parts:
        raise SystemExit("Refusing to write into phase-1 baseline")

    story = load_story(POC_ROOT / "inputs" / "story.txt")
    direction = load_creative_direction(POC_ROOT / "inputs" / "creative_direction.json")
    timeline_a = load_timeline(POC_ROOT / "inputs" / "phase2_timeline_a.json")
    timeline_b = load_timeline(POC_ROOT / "inputs" / "phase2_timeline_b.json")
    adapter = AceStepNarrativeAdapter(
        section_tag_strategy=SectionTagStrategy.NARRATIVE_TAGS,
        disable_inspiration_lm=True,
    )

    duration_override = args.duration
    req_a = adapter.compile(
        story, direction, timeline_a, seed=args.seed, duration_override=duration_override
    )
    req_b = adapter.compile(
        story, direction, timeline_b, seed=args.seed, duration_override=duration_override
    )
    windows_b = expected_phase_windows(timeline_b.to_dict(), req_b.duration)
    breakthrough = _find_window(windows_b, "breakthrough")

    runtime = None
    if not args.dry_run:
        runtime = AceStepRuntime(args.acestep_root, dit_model=args.dit_model)
        runtime.initialize()

    # 1) Base take — Timeline A (intimate) so breakthrough repaint is a clear change.
    base_dir = out_root / f"seed_{args.seed}" / "base_timeline_a"
    base_dir.mkdir(parents=True, exist_ok=True)
    base_params = req_a.generation_params_dict()
    _write_json(base_dir / "compiled.json", base_params)
    _write_json(
        base_dir / "input.json",
        {"request": req_a.to_dict(), "role": "repaint_base", "timestamp": _utc_now()},
    )

    if args.base_audio and args.base_audio.exists():
        dest = base_dir / "audio.wav"
        src = args.base_audio.resolve()
        if src != dest.resolve():
            shutil.copy2(src, dest)
        base_audio = dest
        base_meta = {"status": "copied_base", "audio_path": str(dest)}
    elif args.dry_run:
        base_audio = base_dir / "audio.wav"
        base_meta = {"status": "compiled_only"}
    else:
        assert runtime is not None
        gen = runtime.generate(base_params, save_dir=base_dir / "raw")
        base_meta = {"status": "ok" if gen.get("success") else "failed", "generation": gen}
        base_audio = None
        for audio in gen.get("audios") or []:
            path = audio.get("path") if isinstance(audio, dict) else None
            if path and Path(path).exists():
                base_audio = base_dir / "audio.wav"
                shutil.copy2(path, base_audio)
                break
        if base_audio is None:
            found = list((base_dir / "raw").rglob("*.wav"))
            if found:
                base_audio = base_dir / "audio.wav"
                shutil.copy2(found[0], base_audio)
        base_meta["audio_path"] = str(base_audio) if base_audio else None
    _write_json(base_dir / "generation-metadata.json", base_meta)

    # 2) Repaint breakthrough window using Timeline B caption/lyrics intent.
    repaint_dir = out_root / f"seed_{args.seed}" / "repaint_breakthrough"
    repaint_dir.mkdir(parents=True, exist_ok=True)
    repaint_params = req_b.generation_params_dict()
    repaint_params.update(
        {
            "task_type": "repaint",
            "src_audio": str(base_audio) if base_audio else "",
            "repainting_start": float(breakthrough["start_s"]),
            "repainting_end": float(breakthrough["end_s"]),
            "repaint_mode": "balanced",
            "repaint_strength": float(args.repaint_strength),
            "audio_cover_strength": 0.5,
            "thinking": False,
            "use_cot_metas": False,
            "use_cot_caption": False,
            "use_cot_lyrics": False,
            "use_cot_language": False,
        }
    )
    # Strengthen caption focus on the breakthrough window.
    repaint_params["caption"] = (
        req_b.caption
        + "\n\nREPAINT FOCUS: Only the breakthrough region should become denser, "
        "more rhythmic, and more triumphant; preserve surrounding intimate material."
    )

    _write_json(repaint_dir / "compiled.json", repaint_params)
    _write_json(
        repaint_dir / "input.json",
        {
            "request": req_b.to_dict(),
            "breakthrough_window": breakthrough,
            "base_audio": str(base_audio) if base_audio else None,
            "timestamp": _utc_now(),
        },
    )

    repaint_meta: Dict[str, Any] = {
        "timestamp": _utc_now(),
        "acestep_commit": _git_commit(args.acestep_root),
        "dit_model": args.dit_model,
        "inspiration_lm": "OFF",
        "seed": args.seed,
        "hardware": _hardware_info(),
        "breakthrough_window": breakthrough,
        "repaint_strength": args.repaint_strength,
        "dry_run": args.dry_run,
    }

    if args.dry_run:
        repaint_meta["status"] = "compiled_only"
    else:
        assert runtime is not None
        if not base_audio or not Path(base_audio).exists():
            repaint_meta["status"] = "error"
            repaint_meta["error"] = "base audio missing; cannot repaint"
        else:
            gen = runtime.generate(repaint_params, save_dir=repaint_dir / "raw")
            repaint_meta["generation"] = gen
            repaint_meta["status"] = "ok" if gen.get("success") else "failed"
            for audio in gen.get("audios") or []:
                path = audio.get("path") if isinstance(audio, dict) else None
                if path and Path(path).exists():
                    dest = repaint_dir / "audio.wav"
                    shutil.copy2(path, dest)
                    repaint_meta["audio_path"] = str(dest)
                    break
            if "audio_path" not in repaint_meta:
                found = list((repaint_dir / "raw").rglob("*.wav"))
                if found:
                    dest = repaint_dir / "audio.wav"
                    shutil.copy2(found[0], dest)
                    repaint_meta["audio_path"] = str(dest)

    _write_json(repaint_dir / "generation-metadata.json", repaint_meta)

    # Also emit a full Timeline B reference generation path pointer if present.
    summary = {
        "seed": args.seed,
        "base": base_meta,
        "repaint": {
            "status": repaint_meta.get("status"),
            "audio_path": repaint_meta.get("audio_path"),
            "window": breakthrough,
        },
        "questions": {
            "can_target_time_window": True,  # API supports start/end seconds
            "intent_changed_in_window": "pending_analysis",
            "surrounding_context_preserved": "pending_analysis",
            "transitions_musical": "pending_listening",
            "improves_phase_control": "pending_analysis",
        },
    }
    _write_json(out_root / f"seed_{args.seed}" / "repaint_summary.json", summary)
    print(json.dumps(summary, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
