#!/usr/bin/env python3
"""Phase 2 objective analysis: metrics, phase-boundary alignment, plots."""

from __future__ import annotations

import argparse
import json
import math
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

import numpy as np

POC_ROOT = Path(__file__).resolve().parents[1]


def _load_mono(path: Path) -> Tuple[int, np.ndarray]:
    import soundfile as sf

    y, sr = sf.read(str(path), always_2d=True)
    return int(sr), y.mean(axis=1).astype(np.float64)


def _frame_rms(y: np.ndarray, sr: int, hop_s: float = 0.25, win_s: float = 0.5) -> Tuple[np.ndarray, np.ndarray]:
    hop = max(1, int(hop_s * sr))
    win = max(hop, int(win_s * sr))
    times = []
    vals = []
    for i in range(0, max(1, len(y) - win + 1), hop):
        w = y[i : i + win]
        vals.append(float(np.sqrt(np.mean(w * w))))
        times.append((i + win / 2) / sr)
    return np.asarray(times), np.asarray(vals)


def _spectral_features(y: np.ndarray, sr: int, n_fft: int = 2048, hop: int = 1024) -> Dict[str, Any]:
    if len(y) < n_fft:
        pad = np.zeros(n_fft - len(y))
        y = np.concatenate([y, pad])
    window = np.hanning(n_fft)
    centroids = []
    bandwidths = []
    rolloffs = []
    low_e = []
    mid_e = []
    high_e = []
    times = []
    freqs = np.fft.rfftfreq(n_fft, 1.0 / sr)
    for i in range(0, len(y) - n_fft + 1, hop):
        frame = y[i : i + n_fft] * window
        mag = np.abs(np.fft.rfft(frame)) + 1e-12
        power = mag * mag
        psum = power.sum()
        centroid = float((freqs * power).sum() / psum)
        bw = float(np.sqrt(((freqs - centroid) ** 2 * power).sum() / psum))
        cump = np.cumsum(power)
        roll_idx = int(np.searchsorted(cump, 0.85 * cump[-1]))
        rolloff = float(freqs[min(roll_idx, len(freqs) - 1)])
        low = float(power[freqs < 250].sum() / psum)
        mid = float(power[(freqs >= 250) & (freqs < 2000)].sum() / psum)
        high = float(power[freqs >= 2000].sum() / psum)
        centroids.append(centroid)
        bandwidths.append(bw)
        rolloffs.append(rolloff)
        low_e.append(low)
        mid_e.append(mid)
        high_e.append(high)
        times.append((i + n_fft / 2) / sr)
    return {
        "times": times,
        "spectral_centroid": centroids,
        "spectral_bandwidth": bandwidths,
        "spectral_rolloff": rolloffs,
        "low_energy_frac": low_e,
        "mid_energy_frac": mid_e,
        "high_energy_frac": high_e,
        "mean_centroid": float(np.mean(centroids)) if centroids else 0.0,
        "mean_bandwidth": float(np.mean(bandwidths)) if bandwidths else 0.0,
        "mean_rolloff": float(np.mean(rolloffs)) if rolloffs else 0.0,
    }


def _onset_density(y: np.ndarray, sr: int, hop_s: float = 0.25) -> Tuple[np.ndarray, np.ndarray]:
    # Simple spectral-flux onset proxy.
    n_fft = 1024
    hop = max(1, int(0.01 * sr))
    window = np.hanning(n_fft)
    prev = None
    flux = []
    flux_t = []
    for i in range(0, len(y) - n_fft + 1, hop):
        mag = np.abs(np.fft.rfft(y[i : i + n_fft] * window))
        if prev is None:
            val = 0.0
        else:
            diff = mag - prev
            val = float(np.sum(diff[diff > 0]))
        flux.append(val)
        flux_t.append((i + n_fft / 2) / sr)
        prev = mag
    flux_a = np.asarray(flux)
    if flux_a.size == 0:
        return np.asarray([]), np.asarray([])
    thr = float(np.percentile(flux_a, 85))
    onsets = flux_a > thr
    hop_out = max(1, int(hop_s / (hop / sr)))
    dens_t = []
    dens = []
    for i in range(0, len(onsets), hop_out):
        chunk = onsets[i : i + hop_out]
        dens.append(float(np.mean(chunk)))
        dens_t.append(flux_t[min(i + hop_out // 2, len(flux_t) - 1)])
    return np.asarray(dens_t), np.asarray(dens)


def analyze_wav(path: Path) -> Dict[str, Any]:
    sr, y = _load_mono(path)
    duration = len(y) / sr if sr else 0.0
    peak = float(np.max(np.abs(y))) if len(y) else 0.0
    overall_rms = float(np.sqrt(np.mean(y * y))) if len(y) else 0.0
    t_rms, rms = _frame_rms(y, sr)
    spec = _spectral_features(y, sr)
    t_on, onset = _onset_density(y, sr)
    # Low-energy regions: frames below 20% of median RMS
    med = float(np.median(rms)) if len(rms) else 0.0
    low_mask = rms < (0.2 * med if med > 0 else 0.01)
    low_frac = float(np.mean(low_mask)) if len(rms) else 0.0
    return {
        "path": str(path),
        "sample_rate": sr,
        "duration_s": round(duration, 3),
        "peak_amplitude": round(peak, 6),
        "overall_rms": round(overall_rms, 6),
        "rms_times": [round(float(x), 3) for x in t_rms],
        "rms_envelope": [round(float(x), 6) for x in rms],
        "onset_times": [round(float(x), 3) for x in t_on],
        "onset_density": [round(float(x), 6) for x in onset],
        "low_energy_fraction": round(low_frac, 4),
        "spectral": {
            "mean_centroid": round(spec["mean_centroid"], 2),
            "mean_bandwidth": round(spec["mean_bandwidth"], 2),
            "mean_rolloff": round(spec["mean_rolloff"], 2),
            "times": [round(float(x), 3) for x in spec["times"][::4]],
            "centroid": [round(float(x), 2) for x in spec["spectral_centroid"][::4]],
            "high_energy_frac": [round(float(x), 4) for x in spec["high_energy_frac"][::4]],
            "mean_high_energy_frac": round(float(np.mean(spec["high_energy_frac"])), 4)
            if spec["high_energy_frac"]
            else 0.0,
        },
    }


def phase_alignment(
    analysis: Dict[str, Any], windows: List[Dict[str, Any]]
) -> Dict[str, Any]:
    """Compare intended phase energy targets vs measured mean RMS in windows."""
    times = np.asarray(analysis.get("rms_times") or [], dtype=float)
    rms = np.asarray(analysis.get("rms_envelope") or [], dtype=float)
    onset_t = np.asarray(analysis.get("onset_times") or [], dtype=float)
    onset = np.asarray(analysis.get("onset_density") or [], dtype=float)
    if times.size == 0:
        return {"windows": [], "energy_correlation": None}

    measured = []
    intended_energy = []
    measured_energy = []
    for w in windows:
        mask = (times >= w["start_s"]) & (times < w["end_s"])
        m_rms = float(np.mean(rms[mask])) if np.any(mask) else 0.0
        if onset_t.size:
            omask = (onset_t >= w["start_s"]) & (onset_t < w["end_s"])
            m_onset = float(np.mean(onset[omask])) if np.any(omask) else 0.0
        else:
            m_onset = 0.0
        measured.append(
            {
                "role": w["role"],
                "start_s": w["start_s"],
                "end_s": w["end_s"],
                "intended_energy": w.get("energy"),
                "measured_mean_rms": round(m_rms, 6),
                "measured_mean_onset_density": round(m_onset, 6),
            }
        )
        intended_energy.append(float(w.get("energy") or 0.0))
        measured_energy.append(m_rms)

    corr = None
    if len(intended_energy) >= 2 and np.std(measured_energy) > 1e-9:
        corr = float(np.corrcoef(intended_energy, measured_energy)[0, 1])
    return {
        "windows": measured,
        "energy_correlation": None if corr is None or math.isnan(corr) else round(corr, 4),
    }


def load_expected_windows(meta_path: Path) -> List[Dict[str, Any]]:
    if not meta_path.exists():
        return []
    meta = json.loads(meta_path.read_text(encoding="utf-8"))
    return list(meta.get("expected_phase_windows") or [])


def plot_pair(pair_dir: Path, out_png: Path) -> None:
    import matplotlib

    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    a = pair_dir / "timeline_a" / "audio.wav"
    b = pair_dir / "timeline_b" / "audio.wav"
    if not a.exists() or not b.exists():
        return
    fig, axes = plt.subplots(3, 1, figsize=(12, 9), sharex=True)
    for label, path, color in (
        ("A", a, "#2a6f97"),
        ("B", b, "#bc4749"),
    ):
        analysis = analyze_wav(path)
        axes[0].plot(analysis["rms_times"], analysis["rms_envelope"], label=label, color=color)
        axes[1].plot(
            analysis["spectral"]["times"],
            analysis["spectral"]["high_energy_frac"],
            label=label,
            color=color,
        )
        axes[2].plot(analysis["onset_times"], analysis["onset_density"], label=label, color=color)
    axes[0].set_ylabel("RMS")
    axes[1].set_ylabel("High-band energy frac")
    axes[2].set_ylabel("Onset density")
    axes[2].set_xlabel("seconds")
    for ax in axes:
        ax.grid(True, alpha=0.3)
        ax.legend(loc="upper right")
    # Mark Timeline B intended breakthrough/climax if present
    windows = load_expected_windows(pair_dir / "timeline_b" / "generation-metadata.json")
    for w in windows:
        if w.get("role") in ("breakthrough", "climax", "build"):
            for ax in axes:
                ax.axvspan(w["start_s"], w["end_s"], color="#bc4749", alpha=0.08)
    fig.suptitle(str(pair_dir.relative_to(POC_ROOT / "output")))
    fig.tight_layout()
    out_png.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(out_png, dpi=120)
    plt.close(fig)


def main(argv: Optional[List[str]] = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--output-root",
        type=Path,
        default=POC_ROOT / "output" / "phase-2",
    )
    args = parser.parse_args(argv)
    root: Path = args.output_root
    records: List[Dict[str, Any]] = []
    plots_dir = root / "plots"
    plots_dir.mkdir(parents=True, exist_ok=True)

    for strategy_dir in sorted(root.glob("strategy_*")):
        for seed_dir in sorted(strategy_dir.glob("seed_*")):
            a_wav = seed_dir / "timeline_a" / "audio.wav"
            b_wav = seed_dir / "timeline_b" / "audio.wav"
            if not a_wav.exists() or not b_wav.exists():
                continue
            analysis_a = analyze_wav(a_wav)
            analysis_b = analyze_wav(b_wav)
            windows_a = load_expected_windows(seed_dir / "timeline_a" / "generation-metadata.json")
            windows_b = load_expected_windows(seed_dir / "timeline_b" / "generation-metadata.json")
            align_a = phase_alignment(analysis_a, windows_a)
            align_b = phase_alignment(analysis_b, windows_b)
            # Breakthrough window delta for Timeline B
            bt = next((w for w in align_b["windows"] if w["role"] in ("breakthrough", "climax")), None)
            early = [w for w in align_b["windows"] if w["role"] in ("opening", "vulnerability")]
            early_rms = float(np.mean([w["measured_mean_rms"] for w in early])) if early else 0.0
            record = {
                "strategy": strategy_dir.name.replace("strategy_", "", 1),
                "seed": seed_dir.name,
                "analysis_a": {
                    k: analysis_a[k]
                    for k in (
                        "duration_s",
                        "peak_amplitude",
                        "overall_rms",
                        "low_energy_fraction",
                    )
                },
                "analysis_b": {
                    k: analysis_b[k]
                    for k in (
                        "duration_s",
                        "peak_amplitude",
                        "overall_rms",
                        "low_energy_fraction",
                    )
                },
                "spectral_mean_high_a": analysis_a["spectral"]["mean_high_energy_frac"],
                "spectral_mean_high_b": analysis_b["spectral"]["mean_high_energy_frac"],
                "centroid_a": analysis_a["spectral"]["mean_centroid"],
                "centroid_b": analysis_b["spectral"]["mean_centroid"],
                "phase_alignment_a": align_a,
                "phase_alignment_b": align_b,
                "timeline_b_breakthrough_rms": None if bt is None else bt["measured_mean_rms"],
                "timeline_b_early_rms": round(early_rms, 6),
                "timeline_b_breakthrough_minus_early": None
                if bt is None
                else round(bt["measured_mean_rms"] - early_rms, 6),
                "overall_rms_delta_b_minus_a": round(
                    analysis_b["overall_rms"] - analysis_a["overall_rms"], 6
                ),
            }
            records.append(record)
            plot_pair(
                seed_dir,
                plots_dir / f"{strategy_dir.name}_{seed_dir.name}_ab.png",
            )
            # Persist full envelopes separately for inspection
            (seed_dir / "analysis_a.json").write_text(
                json.dumps(analysis_a, indent=2) + "\n", encoding="utf-8"
            )
            (seed_dir / "analysis_b.json").write_text(
                json.dumps(analysis_b, indent=2) + "\n", encoding="utf-8"
            )

    out = root / "objective_metrics.json"
    out.write_text(json.dumps(records, indent=2) + "\n", encoding="utf-8")
    summary = []
    for r in records:
        summary.append(
            {
                "strategy": r["strategy"],
                "seed": r["seed"],
                "corr_a": r["phase_alignment_a"]["energy_correlation"],
                "corr_b": r["phase_alignment_b"]["energy_correlation"],
                "b_breakthrough_minus_early": r["timeline_b_breakthrough_minus_early"],
                "overall_rms_delta": r["overall_rms_delta_b_minus_a"],
                "high_frac_delta": round(
                    r["spectral_mean_high_b"] - r["spectral_mean_high_a"], 4
                ),
            }
        )
    (root / "objective_summary.json").write_text(
        json.dumps(summary, indent=2) + "\n", encoding="utf-8"
    )
    print(json.dumps({"pairs": len(records), "metrics": str(out)}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
