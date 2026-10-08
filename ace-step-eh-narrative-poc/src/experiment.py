#!/usr/bin/env python3
"""Run controlled NarrativeMusicTimeline A/B experiments against ACE-Step 1.5.

Inspiration LM is disabled. Only the timeline (and optional section-tag strategy)
should vary between matched generations.
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
import traceback
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional

POC_ROOT = Path(__file__).resolve().parents[1]
SRC_ROOT = Path(__file__).resolve().parent
if str(SRC_ROOT) not in sys.path:
    sys.path.insert(0, str(SRC_ROOT))

from ace_step_adapter import (  # noqa: E402
    AceStepNarrativeAdapter,
    SectionTagStrategy,
)
from narrative_music import (  # noqa: E402
    load_creative_direction,
    load_story,
    load_timeline,
)


DEFAULT_SEEDS = [42, 123, 777]
DEFAULT_ACESTEP_ROOT = Path(
    os.environ.get("ACESTEP_ROOT", "/home/ubuntu/ai-poc/ACE-Step-1.5")
)


def _utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def _git_commit(repo: Path) -> str:
    try:
        out = subprocess.check_output(
            ["git", "rev-parse", "HEAD"], cwd=str(repo), text=True
        ).strip()
        return out
    except Exception:
        return "unknown"


def _json_safe(obj: Any) -> Any:
    """Convert nested structures to JSON-serializable forms."""
    if obj is None or isinstance(obj, (str, int, float, bool)):
        return obj
    if isinstance(obj, Path):
        return str(obj)
    if isinstance(obj, dict):
        return {str(k): _json_safe(v) for k, v in obj.items()}
    if isinstance(obj, (list, tuple)):
        return [_json_safe(v) for v in obj]
    # torch.Tensor / numpy / assorted handler objects
    try:
        import torch

        if isinstance(obj, torch.Tensor):
            return {
                "_type": "Tensor",
                "shape": list(obj.shape),
                "dtype": str(obj.dtype),
                "device": str(obj.device),
            }
    except Exception:
        pass
    if hasattr(obj, "item") and callable(obj.item):
        try:
            return obj.item()
        except Exception:
            pass
    if hasattr(obj, "tolist") and callable(obj.tolist):
        try:
            return obj.tolist()
        except Exception:
            pass
    return repr(obj)


def _write_json(path: Path, data: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(_json_safe(data), indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )


def _hardware_info() -> Dict[str, Any]:
    info: Dict[str, Any] = {
        "python": sys.version,
        "platform": sys.platform,
        "cuda_available": False,
        "device": "cpu",
    }
    try:
        import torch

        info["torch"] = torch.__version__
        info["cuda_available"] = bool(torch.cuda.is_available())
        info["device"] = "cuda" if torch.cuda.is_available() else "cpu"
        if torch.cuda.is_available():
            info["cuda_device_name"] = torch.cuda.get_device_name(0)
            info["cuda_device_count"] = torch.cuda.device_count()
    except Exception as exc:
        info["torch_error"] = str(exc)
    try:
        mem = Path("/proc/meminfo").read_text(encoding="utf-8")
        for line in mem.splitlines():
            if line.startswith("MemTotal:"):
                info["mem_total"] = line.split(":", 1)[1].strip()
                break
    except Exception:
        pass
    return info


def compile_pair(
    *,
    strategy: SectionTagStrategy,
    seed: int,
) -> Dict[str, Any]:
    story = load_story(POC_ROOT / "inputs" / "story.txt")
    direction = load_creative_direction(POC_ROOT / "inputs" / "creative_direction.json")
    timeline_a = load_timeline(POC_ROOT / "inputs" / "timeline_a.json")
    timeline_b = load_timeline(POC_ROOT / "inputs" / "timeline_b.json")
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


def _ensure_acestep_on_path(acestep_root: Path) -> None:
    root = str(acestep_root)
    if root not in sys.path:
        sys.path.insert(0, root)


class AceStepRuntime:
    """Keeps DiT loaded across matched A/B generations (Inspiration LM off)."""

    def __init__(self, acestep_root: Path, dit_model: str = "acestep-v15-turbo") -> None:
        self.acestep_root = acestep_root
        self.dit_model = dit_model
        self.dit_handler = None
        self.device = "cpu"

    def initialize(self) -> None:
        _ensure_acestep_on_path(self.acestep_root)
        os.environ.setdefault("ACESTEP_PROJECT_ROOT", str(self.acestep_root))
        os.environ.setdefault(
            "ACESTEP_CHECKPOINTS_DIR", str(self.acestep_root / "checkpoints")
        )
        os.environ["ACESTEP_INIT_LLM"] = "false"

        from acestep.handler import AceStepHandler

        try:
            import torch

            if torch.cuda.is_available():
                self.device = "cuda"
        except Exception:
            pass

        dit_handler = AceStepHandler()
        init_kwargs: Dict[str, Any] = {
            "project_root": str(self.acestep_root),
            "config_path": self.dit_model,
            "device": self.device,
        }
        try:
            dit_handler.initialize_service(**init_kwargs, offload_to_cpu=True)
        except TypeError:
            dit_handler.initialize_service(**init_kwargs)
        self.dit_handler = dit_handler

    def generate(self, params: Dict[str, Any], *, save_dir: Path) -> Dict[str, Any]:
        if self.dit_handler is None:
            self.initialize()

        from acestep.inference import GenerationConfig, GenerationParams, generate_music

        save_dir.mkdir(parents=True, exist_ok=True)
        gen_params = GenerationParams(**params)
        gen_params.thinking = False
        gen_params.use_cot_metas = False
        gen_params.use_cot_caption = False
        gen_params.use_cot_lyrics = False
        gen_params.use_cot_language = False

        seed = int(params.get("seed", -1))
        config = GenerationConfig(
            batch_size=1,
            allow_lm_batch=False,
            use_random_seed=False,
            seeds=[seed] if seed >= 0 else None,
            audio_format="wav",
        )

        result = generate_music(
            self.dit_handler,
            None,  # Inspiration LM OFF
            gen_params,
            config,
            save_dir=str(save_dir),
        )

        payload: Dict[str, Any] = {
            "success": bool(getattr(result, "success", False)),
            "status_message": getattr(result, "status_message", None),
            "error": getattr(result, "error", None),
            "device": self.device,
            "dit_model": self.dit_model,
            "inspiration_lm": "OFF",
            "audios": [],
        }
        audios = getattr(result, "audios", None) or []
        for audio in audios:
            if isinstance(audio, dict):
                payload["audios"].append(audio)
            else:
                payload["audios"].append({"raw": repr(audio)})
        extra = getattr(result, "extra_outputs", None)
        if extra is not None:
            try:
                payload["extra_outputs"] = (
                    dict(extra) if hasattr(extra, "items") else repr(extra)
                )
            except Exception:
                payload["extra_outputs"] = repr(extra)
        return payload


def generate_with_acestep(
    params: Dict[str, Any],
    *,
    save_dir: Path,
    acestep_root: Path,
    dit_model: str = "acestep-v15-turbo",
    runtime: Optional[AceStepRuntime] = None,
) -> Dict[str, Any]:
    """Invoke ACE-Step generate_music with Inspiration LM disabled."""
    rt = runtime or AceStepRuntime(acestep_root, dit_model=dit_model)
    if rt.dit_handler is None:
        rt.initialize()
    return rt.generate(params, save_dir=save_dir)


def run_one(
    *,
    timeline_key: str,
    request: Dict[str, Any],
    params: Dict[str, Any],
    out_dir: Path,
    acestep_root: Path,
    dry_run: bool,
    dit_model: str,
    runtime: Optional[AceStepRuntime] = None,
) -> Dict[str, Any]:
    out_dir.mkdir(parents=True, exist_ok=True)
    input_payload = {
        "timeline_key": timeline_key,
        "timestamp": _utc_now(),
        "request": request,
    }
    _write_json(out_dir / "input.json", input_payload)
    _write_json(out_dir / "compiled.json", params)

    meta: Dict[str, Any] = {
        "timestamp": _utc_now(),
        "acestep_root": str(acestep_root),
        "acestep_commit": _git_commit(acestep_root),
        "acestep_version": "1.5.0",
        "dit_model": dit_model,
        "inspiration_lm": "OFF",
        "inspiration_lm_disable_method": (
            "thinking=False, use_cot_*=False, llm_handler=None, ACESTEP_INIT_LLM=false"
        ),
        "seed": params.get("seed"),
        "duration": params.get("duration"),
        "bpm": params.get("bpm"),
        "keyscale": params.get("keyscale"),
        "language": params.get("vocal_language"),
        "section_tag_strategy": request.get("section_tag_strategy"),
        "timeline_name": request.get("timeline_name"),
        "hardware": _hardware_info(),
        "dry_run": dry_run,
        "source_files": {
            "story": str(POC_ROOT / "inputs" / "story.txt"),
            "creative_direction": str(POC_ROOT / "inputs" / "creative_direction.json"),
            "timeline_a": str(POC_ROOT / "inputs" / "timeline_a.json"),
            "timeline_b": str(POC_ROOT / "inputs" / "timeline_b.json"),
        },
    }

    if dry_run:
        meta["status"] = "compiled_only"
        _write_json(out_dir / "generation-metadata.json", meta)
        return meta

    try:
        gen = generate_with_acestep(
            params,
            save_dir=out_dir / "raw",
            acestep_root=acestep_root,
            dit_model=dit_model,
            runtime=runtime,
        )
        meta["generation"] = gen
        meta["status"] = "ok" if gen.get("success") else "failed"
        # Promote a primary audio.* into out_dir if present.
        for audio in gen.get("audios") or []:
            path = audio.get("path") if isinstance(audio, dict) else None
            if path and Path(path).exists():
                dest = out_dir / f"audio{Path(path).suffix}"
                shutil.copy2(path, dest)
                meta["audio_path"] = str(dest)
                break
        # Also scan save_dir for audio files.
        if "audio_path" not in meta:
            for pattern in ("*.wav", "*.flac", "*.mp3"):
                found = list((out_dir / "raw").rglob(pattern))
                if found:
                    dest = out_dir / f"audio{found[0].suffix}"
                    shutil.copy2(found[0], dest)
                    meta["audio_path"] = str(dest)
                    break
    except Exception as exc:
        meta["status"] = "error"
        meta["error"] = str(exc)
        meta["traceback"] = traceback.format_exc()

    _write_json(out_dir / "generation-metadata.json", meta)
    return meta


def main(argv: Optional[List[str]] = None) -> int:
    parser = argparse.ArgumentParser(description="ACE-Step EH Narrative Music POC experiment")
    parser.add_argument("--acestep-root", type=Path, default=DEFAULT_ACESTEP_ROOT)
    parser.add_argument("--dit-model", default="acestep-v15-turbo")
    parser.add_argument(
        "--seeds",
        default=",".join(str(s) for s in DEFAULT_SEEDS),
        help="Comma-separated seeds for matched A/B pairs",
    )
    parser.add_argument(
        "--strategies",
        default="natural_tags,caption_only",
        help="Comma-separated: natural_tags,caption_only",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Compile adapter outputs only; do not run ACE-Step generation",
    )
    parser.add_argument(
        "--output-root",
        type=Path,
        default=POC_ROOT / "output",
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

    run_manifest: Dict[str, Any] = {
        "started_at": _utc_now(),
        "acestep_root": str(args.acestep_root),
        "acestep_commit": _git_commit(args.acestep_root),
        "dit_model": args.dit_model,
        "seeds": seeds,
        "strategies": [s.value for s in strategies],
        "dry_run": args.dry_run,
        "hardware": _hardware_info(),
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
            compiled = compile_pair(strategy=strategy, seed=seed)
            pair_dir = (
                args.output_root
                / f"strategy_{strategy.value}"
                / f"seed_{seed}"
            )
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
            # Convenience mirrors for the primary strategy/seed into classic paths.
            if strategy == SectionTagStrategy.NATURAL_TAGS and seed == seeds[0]:
                for src_name, meta in (("timeline_a", meta_a), ("timeline_b", meta_b)):
                    classic = args.output_root / src_name
                    classic.mkdir(parents=True, exist_ok=True)
                    src = pair_dir / src_name
                    for fname in (
                        "input.json",
                        "compiled.json",
                        "generation-metadata.json",
                    ):
                        if (src / fname).exists():
                            shutil.copy2(src / fname, classic / fname)
                    for audio in src.glob("audio.*"):
                        shutil.copy2(audio, classic / audio.name)

            run_manifest["results"].append(
                {
                    "strategy": strategy.value,
                    "seed": seed,
                    "timeline_a": meta_a,
                    "timeline_b": meta_b,
                }
            )

    run_manifest["finished_at"] = _utc_now()
    _write_json(args.output_root / "run_manifest.json", run_manifest)
    print(json.dumps({"status": "done", "manifest": str(args.output_root / "run_manifest.json")}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
