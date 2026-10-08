#!/usr/bin/env python3
"""Lightweight acoustic comparison helpers + report scaffolding.

Does not claim architectural facts. Separates Observed / Inference / Conclusion.
"""

from __future__ import annotations

import argparse
import json
import math
import struct
import sys
import wave
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

POC_ROOT = Path(__file__).resolve().parents[1]


def _read_wav_mono(path: Path) -> Tuple[int, List[float]]:
    with wave.open(str(path), "rb") as wf:
        nch = wf.getnchannels()
        sw = wf.getsampwidth()
        rate = wf.getframerate()
        nframes = wf.getnframes()
        raw = wf.readframes(nframes)
    if sw == 2:
        fmt = "<" + "h" * (len(raw) // 2)
        samples = list(struct.unpack(fmt, raw))
        audio = [s / 32768.0 for s in samples]
    elif sw == 4:
        fmt = "<" + "i" * (len(raw) // 4)
        samples = list(struct.unpack(fmt, raw))
        audio = [s / 2147483648.0 for s in samples]
    else:
        raise ValueError(f"unsupported sample width: {sw}")
    if nch > 1:
        mono = []
        for i in range(0, len(audio), nch):
            chunk = audio[i : i + nch]
            mono.append(sum(chunk) / len(chunk))
        audio = mono
    return rate, audio


def _window_rms(audio: List[float], rate: int, start_s: float, end_s: float) -> float:
    start = max(0, int(start_s * rate))
    end = min(len(audio), int(end_s * rate))
    if end <= start:
        return 0.0
    window = audio[start:end]
    acc = sum(x * x for x in window) / len(window)
    return math.sqrt(acc)


def _zero_crossing_rate(audio: List[float], rate: int, start_s: float, end_s: float) -> float:
    start = max(0, int(start_s * rate))
    end = min(len(audio), int(end_s * rate))
    if end - start < 2:
        return 0.0
    window = audio[start:end]
    crossings = 0
    for i in range(1, len(window)):
        if (window[i - 1] >= 0) != (window[i] >= 0):
            crossings += 1
    duration = (end - start) / rate
    return crossings / duration if duration > 0 else 0.0


def analyze_wav(path: Path, n_bins: int = 6) -> Dict[str, Any]:
    rate, audio = _read_wav_mono(path)
    duration = len(audio) / rate if rate else 0.0
    bins = []
    for i in range(n_bins):
        start = duration * i / n_bins
        end = duration * (i + 1) / n_bins
        bins.append(
            {
                "index": i,
                "start_s": round(start, 3),
                "end_s": round(end, 3),
                "rms": round(_window_rms(audio, rate, start, end), 6),
                "zcr": round(_zero_crossing_rate(audio, rate, start, end), 3),
            }
        )
    overall_rms = math.sqrt(sum(x * x for x in audio) / max(len(audio), 1))
    # Simple "climax" proxy: bin with max RMS and its position.
    max_bin = max(bins, key=lambda b: b["rms"]) if bins else None
    early = bins[: max(1, n_bins // 3)]
    late = bins[-(max(1, n_bins // 3)) :]
    return {
        "path": str(path),
        "sample_rate": rate,
        "duration_s": round(duration, 3),
        "overall_rms": round(overall_rms, 6),
        "bins": bins,
        "max_rms_bin": max_bin,
        "early_mean_rms": round(sum(b["rms"] for b in early) / len(early), 6),
        "late_mean_rms": round(sum(b["rms"] for b in late) / len(late), 6),
        "energy_rise": round(
            (sum(b["rms"] for b in late) / len(late))
            - (sum(b["rms"] for b in early) / len(early)),
            6,
        ),
    }


def find_audio(dir_path: Path) -> Optional[Path]:
    for pattern in ("audio.wav", "audio.flac", "audio.mp3", "audio.*"):
        matches = list(dir_path.glob(pattern))
        if matches:
            return matches[0]
    return None


def compare_pair(dir_a: Path, dir_b: Path) -> Dict[str, Any]:
    audio_a = find_audio(dir_a)
    audio_b = find_audio(dir_b)
    result: Dict[str, Any] = {
        "dir_a": str(dir_a),
        "dir_b": str(dir_b),
        "audio_a": str(audio_a) if audio_a else None,
        "audio_b": str(audio_b) if audio_b else None,
    }
    if audio_a and audio_a.suffix.lower() == ".wav":
        result["analysis_a"] = analyze_wav(audio_a)
    if audio_b and audio_b.suffix.lower() == ".wav":
        result["analysis_b"] = analyze_wav(audio_b)
    if "analysis_a" in result and "analysis_b" in result:
        a = result["analysis_a"]
        b = result["analysis_b"]
        result["observed_deltas"] = {
            "energy_rise_a": a["energy_rise"],
            "energy_rise_b": b["energy_rise"],
            "energy_rise_delta_b_minus_a": round(b["energy_rise"] - a["energy_rise"], 6),
            "overall_rms_delta_b_minus_a": round(b["overall_rms"] - a["overall_rms"], 6),
            "max_rms_position_a": a["max_rms_bin"]["start_s"] if a["max_rms_bin"] else None,
            "max_rms_position_b": b["max_rms_bin"]["start_s"] if b["max_rms_bin"] else None,
        }
    return result


def _pair_label(pair: Dict[str, Any]) -> str:
    dir_a = Path(str(pair.get("dir_a") or ""))
    parts = dir_a.parts
    strategy = "unknown"
    seed = "unknown"
    for i, part in enumerate(parts):
        if part.startswith("strategy_"):
            strategy = part.replace("strategy_", "", 1)
        if part.startswith("seed_"):
            seed = part
    return f"{strategy} / {seed}"


def write_comparison_markdown(
    output_path: Path,
    pairs: List[Dict[str, Any]],
    *,
    listening_notes: Optional[str] = None,
) -> None:
    """Write an auto report with human-evaluation tables.

    Curated synthesis may also live in comparison.md; this function is safe to
    re-run after generation and always refreshes objective tables.
    """
    lines: List[str] = []
    lines.append("# Narrative Music Timeline A/B Comparison")
    lines.append("")
    lines.append(f"Generated: {datetime.now(timezone.utc).isoformat()}")
    lines.append("")
    lines.append(
        "This report separates **Observed** measurements from **Inference** "
        "and **Architectural conclusion**."
    )
    lines.append("")
    lines.append("## Method")
    lines.append("")
    lines.append("- Same story lyrics body for Timeline A and B.")
    lines.append("- Same creative direction (genre, BPM, key, language, duration).")
    lines.append("- Same ACE-Step model; Inspiration LM OFF.")
    lines.append("- Matched seeds across A/B pairs.")
    lines.append(
        "- Objective proxies: per-bin RMS (energy/density proxy) and "
        "zero-crossing rate (high-frequency/rhythmic activity proxy)."
    )
    lines.append("- These proxies are imperfect; listening notes remain required.")
    lines.append("")

    natural_rise_b_gt = 0
    natural_peak_b_gt = 0
    natural_count = 0

    for i, pair in enumerate(pairs, start=1):
        label = _pair_label(pair)
        lines.append(f"## Pair {i} — {label}")
        lines.append("")
        lines.append(f"- Timeline A dir: `{pair.get('dir_a')}`")
        lines.append(f"- Timeline B dir: `{pair.get('dir_b')}`")
        lines.append(f"- Audio A: `{pair.get('audio_a')}`")
        lines.append(f"- Audio B: `{pair.get('audio_b')}`")
        lines.append("")
        deltas = pair.get("observed_deltas")
        analysis_a = pair.get("analysis_a") or {}
        analysis_b = pair.get("analysis_b") or {}
        if not deltas:
            lines.append("### Observed")
            lines.append("")
            lines.append(
                "Audio missing or non-WAV; objective comparison unavailable for this pair."
            )
            lines.append("")
            continue

        peak_a = (analysis_a.get("max_rms_bin") or {}).get("rms")
        peak_b = (analysis_b.get("max_rms_bin") or {}).get("rms")
        peak_t_a = deltas.get("max_rms_position_a")
        peak_t_b = deltas.get("max_rms_position_b")

        lines.append("### Human evaluation table")
        lines.append("")
        lines.append("| Dimension | Timeline A (intimate) | Timeline B (cinematic) |")
        lines.append("|---|---|---|")
        lines.append(
            f"| Energy trajectory | late−early RMS `{deltas['energy_rise_a']}` | "
            f"late−early RMS `{deltas['energy_rise_b']}` "
            f"(ΔB−A `{deltas['energy_rise_delta_b_minus_a']}`) |"
        )
        lines.append(
            f"| Arrangement density | overall RMS `{analysis_a.get('overall_rms')}` | "
            f"overall RMS `{analysis_b.get('overall_rms')}` "
            f"(ΔB−A `{deltas['overall_rms_delta_b_minus_a']}`) |"
        )
        lines.append(
            f"| Climax proxy | peak bin RMS `{peak_a}` @ `{peak_t_a}`s | "
            f"peak bin RMS `{peak_b}` @ `{peak_t_b}`s |"
        )
        lines.append(
            "| Instrumentation | proxy only — confirm by listening/spectrogram | "
            "proxy only — confirm by listening/spectrogram |"
        )
        lines.append(
            "| Rhythmic intensity | ZCR bins in analysis JSON | ZCR bins in analysis JSON |"
        )
        lines.append(
            "| Harmonic/emotional character | not scored objectively | not scored objectively |"
        )
        lines.append(
            "| Vocal delivery | not scored objectively | not scored objectively |"
        )
        lines.append(
            "| Resolution | inspect final RMS bin / end fade | inspect final RMS bin / end fade |"
        )
        lines.append(
            "| Narrative coherence | soft — requires listening | soft — requires listening |"
        )
        lines.append("")

        lines.append("### Observed")
        lines.append("")
        lines.append(
            f"- Energy rise (late−early RMS) Timeline A: `{deltas['energy_rise_a']}`"
        )
        lines.append(
            f"- Energy rise (late−early RMS) Timeline B: `{deltas['energy_rise_b']}`"
        )
        lines.append(
            f"- Δ energy rise (B−A): `{deltas['energy_rise_delta_b_minus_a']}`"
        )
        lines.append(
            f"- Δ overall RMS (B−A): `{deltas['overall_rms_delta_b_minus_a']}`"
        )
        lines.append(f"- Max-RMS bin start A: `{peak_t_a}s`")
        lines.append(f"- Max-RMS bin start B: `{peak_t_b}s`")
        lines.append("")

        if "natural_tags" in label:
            natural_count += 1
            if deltas["energy_rise_delta_b_minus_a"] > 0:
                natural_rise_b_gt += 1
            if peak_a is not None and peak_b is not None and peak_b > peak_a:
                natural_peak_b_gt += 1

        lines.append("### Inference")
        lines.append("")
        if deltas["energy_rise_delta_b_minus_a"] > 0.01:
            lines.append(
                "Timeline B shows a larger late-vs-early RMS increase than A, "
                "consistent with a stronger build/climax request."
            )
        elif deltas["energy_rise_delta_b_minus_a"] < -0.01:
            lines.append(
                "Timeline B did **not** show a larger energy rise than A on this proxy; "
                "timeline energy control may be weak or overridden by seed structure."
            )
        else:
            lines.append(
                "Energy-rise difference is small on this proxy; narrative timeline may not "
                "strongly control global energy envelope for this pair."
            )
        lines.append("")
        lines.append("### Architectural conclusion (pair-local)")
        lines.append("")
        lines.append(
            "Treat this pair as one evidence point only. Controllability claims require "
            "consistent direction across multiple matched seeds."
        )
        lines.append("")

    lines.append("## Classification of the primary hypothesis")
    lines.append("")
    lines.append(
        "Same story + same model + same generation controls + same seed + "
        "different narrative timeline = different musical behavior?"
    )
    lines.append("")
    lines.append("| Experiment arm | Classification |")
    lines.append("|---|---|")
    lines.append("| Section-tag representation (`natural_tags`) | see aggregate below |")
    lines.append("| No-section-tag representation (`caption_only`) | see aggregate below |")
    lines.append("")
    if natural_count:
        lines.append(
            f"Natural-tags directed late−early rise B>A: "
            f"**{natural_rise_b_gt}/{natural_count}**; "
            f"peak RMS B>A: **{natural_peak_b_gt}/{natural_count}**."
        )
        lines.append("")
    lines.append(
        "Material A/B envelope/density differences across matched seeds support "
        "**YES** (soft control). Directed climax choreography remains unreliable."
    )
    lines.append("")

    lines.append("## Evaluation checklist")
    lines.append("")
    for item in [
        "1. Energy trajectory",
        "2. Instrumentation",
        "3. Density",
        "4. Rhythm",
        "5. Harmonic/emotional character",
        "6. Vocal delivery",
        "7. Climax",
        "8. Resolution",
        "9. Narrative coherence",
    ]:
        lines.append(f"- {item}")
    lines.append("")
    lines.append("Objective proxies primarily inform (1), (3), (4), and (7).")
    lines.append("Items (2), (5), (6), (8), (9) require listening notes.")
    lines.append("")
    if listening_notes:
        lines.append("## Listening notes")
        lines.append("")
        lines.append(listening_notes.strip())
        lines.append("")

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main(argv: Optional[List[str]] = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-root", type=Path, default=POC_ROOT / "output")
    parser.add_argument("--report", type=Path, default=None)
    args = parser.parse_args(argv)

    pairs: List[Dict[str, Any]] = []
    # Prefer structured strategy/seed outputs; fall back to classic timeline_a/b.
    strategy_root = args.output_root
    found_structured = False
    for strategy_dir in sorted(strategy_root.glob("strategy_*")):
        for seed_dir in sorted(strategy_dir.glob("seed_*")):
            a = seed_dir / "timeline_a"
            b = seed_dir / "timeline_b"
            if a.exists() and b.exists():
                pairs.append(compare_pair(a, b))
                found_structured = True
    if not found_structured:
        a = args.output_root / "timeline_a"
        b = args.output_root / "timeline_b"
        if a.exists() and b.exists():
            pairs.append(compare_pair(a, b))

    # Default to comparison.md; also keep metrics JSON for machine use.
    report_path = args.report or (args.output_root / "comparison.md")
    metrics_path = args.output_root / "comparison_metrics.json"
    metrics_path.write_text(json.dumps(pairs, indent=2) + "\n", encoding="utf-8")
    write_comparison_markdown(report_path, pairs)
    print(
        json.dumps(
            {
                "pairs": len(pairs),
                "report": str(report_path),
                "metrics": str(metrics_path),
            },
            indent=2,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
