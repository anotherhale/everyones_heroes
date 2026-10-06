"""Compile Narrative Music Timeline → ACE-Step GenerationParams.

Deterministic. No network. No ACE-Step imports.
Inspiration LM flags are forced off so EH owns the plan.
"""

from __future__ import annotations

from .models import (
    AceGenerationParams,
    AceGenerationRequest,
    CompilerMode,
    NarrativeMusicTimeline,
    NarrativePhase,
    PhaseWindow,
    StorySeed,
)

# Soft compiler backend only — not EH ontology.
_CONVENTIONAL_MAP: dict[str, str] = {
    "opening": "Intro",
    "challenge": "Verse",
    "struggle": "Verse",
    "turning_point": "Pre-Chorus",
    "breakthrough": "Chorus",
    "resolution": "Outro",
    # Friendly aliases
    "intro": "Intro",
    "verse": "Verse",
    "chorus": "Chorus",
    "bridge": "Bridge",
    "outro": "Outro",
}


def _normalize_phase_key(name: str) -> str:
    return name.strip().lower().replace(" ", "_").replace("-", "_")


def _tag_for_phase(phase: NarrativePhase, mode: CompilerMode) -> str:
    key = _normalize_phase_key(phase.name)
    if mode is CompilerMode.CONVENTIONAL:
        label = _CONVENTIONAL_MAP.get(key, phase.name.title())
        return f"[{label}]"
    # EH semantic tags — open vocabulary (ACE-Step has no section allowlist).
    words = phase.name.strip().replace("_", " ").replace("-", " ")
    title = " ".join(w.capitalize() for w in words.split())
    return f"[{title}]"


def _energy_descriptor(energy: float) -> str:
    if energy < 0.25:
        return "sparse, restrained, low energy"
    if energy < 0.45:
        return "held tension, moderate-low energy"
    if energy < 0.65:
        return "building drive, medium energy"
    if energy < 0.85:
        return "powerful, elevated energy"
    return "peak intensity, triumphant/full"


def _format_time(seconds: float) -> str:
    m = int(seconds) // 60
    s = int(seconds) % 60
    return f"{m}:{s:02d}"


def _compile_caption(
    seed: StorySeed,
    timeline: NarrativeMusicTimeline,
) -> str:
    """Arc production brief with soft absolute timing (ACE has no hard phase graph)."""
    phases = timeline.sorted_phases()
    lines: list[str] = [
        f"Instrumental narrative underscore for story: {seed.title}.",
        seed.style_brief.rstrip(".") + ".",
        f"Narrative summary: {seed.narrative_summary}",
        f"Total duration {_format_time(timeline.duration_seconds)} "
        f"({timeline.duration_seconds:.0f}s).",
        "Follow this timed emotional arc precisely:",
    ]
    for phase in phases:
        lines.append(
            f"- {_format_time(phase.start_seconds)}–{_format_time(phase.end_seconds)} "
            f"{phase.name}: {phase.emotional_state}; "
            f"{_energy_descriptor(phase.energy)}; {phase.musical_intent}"
        )
    lines.append(
        "Continuous single-bed instrumental; no vocals; no pop song form required; "
        "evolve texture and dynamics with the arc rather than verse/chorus formulas."
    )
    if timeline.notes.strip():
        lines.append(f"Timeline notes: {timeline.notes.strip()}")
    return "\n".join(lines)


def _compile_lyrics(
    seed: StorySeed,
    timeline: NarrativeMusicTimeline,
    mode: CompilerMode,
) -> str:
    """Phase tags inside lyrics string — ACE-Step's only structure channel."""
    if seed.instrumental:
        parts: list[str] = ["[Instrumental]"]
    else:
        parts = []

    for phase in timeline.sorted_phases():
        tag = _tag_for_phase(phase, mode)
        parts.append(tag)
        # Approximate textual proportion via short intent lines (soft control).
        intent = phase.lyric_intent or phase.musical_intent
        parts.append(intent.strip())
        parts.append(f"({_energy_descriptor(phase.energy)})")
        parts.append("")  # blank line between phases

    return "\n".join(parts).rstrip() + "\n"


def _phase_windows(timeline: NarrativeMusicTimeline) -> tuple[PhaseWindow, ...]:
    return tuple(
        PhaseWindow(
            phase_name=p.name,
            start_seconds=p.start_seconds,
            end_seconds=p.end_seconds,
            energy=p.energy,
        )
        for p in timeline.sorted_phases()
    )


def compile_timeline(
    seed: StorySeed,
    timeline: NarrativeMusicTimeline,
    *,
    mode: CompilerMode = CompilerMode.EH_TAGS,
    seed_value: int = 42,
    model_hint: str = "acestep-v15-turbo",
) -> AceGenerationRequest:
    """Deterministically compile one timeline into an ACE-Step-shaped request.

    Inspiration LM is forced off. Caption/lyrics are fully EH-owned.
    """
    if seed.story_id != timeline.story_id:
        raise ValueError(
            f"story_id mismatch: seed={seed.story_id!r} timeline={timeline.story_id!r}"
        )

    caption = _compile_caption(seed, timeline)
    lyrics = _compile_lyrics(seed, timeline, mode)
    duration = timeline.duration_seconds

    params = AceGenerationParams(
        caption=caption,
        lyrics=lyrics,
        duration=duration,
        bpm=seed.bpm,
        keyscale=seed.keyscale,
        vocal_language=seed.language if not seed.instrumental else "unknown",
        instrumental=seed.instrumental,
        thinking=False,
        use_llm_inspiration=False,
        format_lyrics_with_llm=False,
        seed=seed_value,
        model_hint=model_hint,
    )

    return AceGenerationRequest(
        params=params,
        phase_windows=_phase_windows(timeline),
        timeline_id=timeline.timeline_id,
        story_id=seed.story_id,
        compiler_mode=mode,
        inspiration_lm_off=True,
        provenance={
            "spike": "ace-step-eh-adapter",
            "architecture": "Option B",
            "story_title": seed.title,
            "timeline_label": timeline.label,
            "phase_count": len(timeline.phases),
            "controls": {
                "same_story": True,
                "inspiration_lm": "off",
                "dit_vae": "unchanged",
            },
        },
    )


def repaint_window_for_phase(
    request: AceGenerationRequest,
    phase_name: str,
) -> dict[str, float | str]:
    """Map a phase name → ACE-Step repaint seconds (adapter-owned)."""
    key = _normalize_phase_key(phase_name)
    for window in request.phase_windows:
        if _normalize_phase_key(window.phase_name) == key:
            return {
                "task_type": "repaint",
                "phase_name": window.phase_name,
                "repainting_start": window.start_seconds,
                "repainting_end": window.end_seconds,
            }
    raise KeyError(f"phase not found in request: {phase_name!r}")
