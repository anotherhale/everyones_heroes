"""ACE-Step adapter: compiles provider-neutral narrative music into ACE-Step inputs.

ACE-Step-specific concepts stop at this boundary.
"""

from __future__ import annotations

from dataclasses import asdict, dataclass, field
from enum import Enum
from typing import Any, Dict, List, Optional, Sequence

from narrative_music import (
    MusicCreativeDirection,
    NarrativeMusicSegment,
    NarrativeMusicTimeline,
    StoryText,
    allocate_story_lines,
)


class SectionTagStrategy(str, Enum):
    """Two compilation strategies for the section-tag hypothesis."""

    NATURAL_TAGS = "natural_tags"
    CAPTION_ONLY = "caption_only"


# Map narrative roles → open-ended section tags (not Verse/Chorus ontology).
ROLE_TO_TAG = {
    "opening": "Opening",
    "struggle": "Struggle",
    "hope": "Turning Point",
    "challenge": "Challenge",
    "determination": "Determination",
    "breakthrough": "Breakthrough",
    "resolution": "Resolution",
}


@dataclass(frozen=True)
class AceStepGenerationRequest:
    """Flat ACE-Step generation contract produced by the adapter only."""

    caption: str
    lyrics: str
    bpm: int
    keyscale: str
    timesignature: str
    vocal_language: str
    duration: float
    seed: int
    thinking: bool
    use_cot_metas: bool
    use_cot_caption: bool
    use_cot_lyrics: bool
    use_cot_language: bool
    instrumental: bool
    inference_steps: int
    guidance_scale: float
    task_type: str
    section_tag_strategy: str
    timeline_name: str
    metadata: Dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> Dict[str, Any]:
        return asdict(self)

    def generation_params_dict(self) -> Dict[str, Any]:
        """Subset suitable for ACE-Step GenerationParams."""
        return {
            "task_type": self.task_type,
            "caption": self.caption,
            "lyrics": self.lyrics,
            "instrumental": self.instrumental,
            "bpm": self.bpm,
            "keyscale": self.keyscale,
            "timesignature": self.timesignature,
            "vocal_language": self.vocal_language,
            "duration": self.duration,
            "seed": self.seed,
            "thinking": self.thinking,
            "use_cot_metas": self.use_cot_metas,
            "use_cot_caption": self.use_cot_caption,
            "use_cot_lyrics": self.use_cot_lyrics,
            "use_cot_language": self.use_cot_language,
            "inference_steps": self.inference_steps,
            "guidance_scale": self.guidance_scale,
        }


def _tag_for_role(role: str) -> str:
    return ROLE_TO_TAG.get(role.lower(), role.replace("_", " ").title())


def _energy_phrase(energy: float) -> str:
    if energy < 0.35:
        return "low energy, spacious"
    if energy < 0.55:
        return "moderate energy"
    if energy < 0.75:
        return "rising energy, denser arrangement"
    return "high energy, climactic intensity"


def _segment_window(
    segments: Sequence[NarrativeMusicSegment], index: int, start: float
) -> tuple[float, float]:
    seg = segments[index]
    end = start + float(seg.duration_seconds)
    return start, end


def _build_caption(
    direction: MusicCreativeDirection,
    timeline: NarrativeMusicTimeline,
    strategy: SectionTagStrategy,
) -> str:
    parts: List[str] = [
        f"A {direction.genre} song. {direction.style}.",
        f"Vocal character: {direction.vocal_character}.",
        f"Core instrumentation palette: {', '.join(direction.instrumentation)}.",
        f"Narrative arc name: {timeline.name}.",
    ]
    if timeline.description:
        parts.append(timeline.description.rstrip(".") + ".")

    parts.append("Musical narrative progression with approximate timing:")
    t = 0.0
    for i, seg in enumerate(timeline.segments):
        start, end = _segment_window(timeline.segments, i, t)
        instruments = ", ".join(seg.instrumentation)
        parts.append(
            f"- {start:.0f}–{end:.0f}s [{seg.role}]: "
            f"{seg.narrative_intent}; mood {seg.emotional_state}; "
            f"{_energy_phrase(seg.energy)}; instrumentation {instruments}; "
            f"vocal delivery {seg.vocal_delivery}."
        )
        t = end

    if strategy == SectionTagStrategy.CAPTION_ONLY:
        parts.append(
            "Do not rely on lyric section labels; follow this timed musical narrative "
            "through arrangement density, rhythm, and vocal intensity alone."
        )
    else:
        parts.append(
            "Follow the narrative section labels present in the lyrics; each tagged "
            "section should match the timed musical intent above."
        )

    # Keep caption under ACE-Step soft limit (~512 chars is documented soft;
    # we allow a longer detailed caption because DiT accepts free-form text,
    # but still avoid extreme length).
    caption = " ".join(parts) if False else "\n".join(parts)
    return caption.strip()


def _build_lyrics_with_tags(
    story: StoryText, timeline: NarrativeMusicTimeline
) -> str:
    chunks = allocate_story_lines(story, timeline.segments)
    blocks: List[str] = []
    for seg, lines in zip(timeline.segments, chunks):
        tag = _tag_for_role(seg.role)
        # Tutorial-style open tags with soft descriptors.
        descriptor = f"{seg.emotional_state} - {_energy_phrase(seg.energy)}"
        blocks.append(f"[{tag} - {descriptor}]\n" + "\n".join(lines))
    return "\n\n".join(blocks).strip() + "\n"


def _build_lyrics_plain(
    story: StoryText, timeline: NarrativeMusicTimeline
) -> str:
    """Same story line allocation, no explicit section tags."""
    chunks = allocate_story_lines(story, timeline.segments)
    # Preserve identical lyric text content (story words only), no tags.
    # Join in segment order without labels so lyrics stay story-identical.
    lines: List[str] = []
    for chunk in chunks:
        lines.extend(chunk)
    # Use original story line order for true lyric identity.
    return "\n".join(story.lines).strip() + "\n"


def story_lyric_body(story: StoryText) -> str:
    """Story words only — used to assert A/B lyric identity."""
    return "\n".join(story.lines).strip()


def extract_lyric_body(lyrics: str) -> str:
    """Strip section tags / blank lines for body comparison."""
    out: List[str] = []
    for line in lyrics.splitlines():
        stripped = line.strip()
        if not stripped:
            continue
        if stripped.startswith("[") and stripped.endswith("]"):
            continue
        out.append(stripped)
    return "\n".join(out)


class AceStepNarrativeAdapter:
    """Compile Story + CreativeDirection + Timeline → ACE-Step request."""

    def __init__(
        self,
        *,
        section_tag_strategy: SectionTagStrategy = SectionTagStrategy.NATURAL_TAGS,
        inference_steps: int = 8,
        guidance_scale: float = 7.0,
        disable_inspiration_lm: bool = True,
    ) -> None:
        self.section_tag_strategy = section_tag_strategy
        self.inference_steps = inference_steps
        self.guidance_scale = guidance_scale
        self.disable_inspiration_lm = disable_inspiration_lm

    def compile(
        self,
        story: StoryText,
        direction: MusicCreativeDirection,
        timeline: NarrativeMusicTimeline,
        *,
        seed: int,
        duration_override: Optional[float] = None,
    ) -> AceStepGenerationRequest:
        strategy = self.section_tag_strategy
        caption = _build_caption(direction, timeline, strategy)
        if strategy == SectionTagStrategy.NATURAL_TAGS:
            lyrics = _build_lyrics_with_tags(story, timeline)
        else:
            lyrics = _build_lyrics_plain(story, timeline)

        duration = float(
            duration_override
            if duration_override is not None
            else direction.duration_seconds
        )
        # Prefer shared creative-direction duration so A/B stay matched.
        # Timeline segment durations inform caption windows only.

        thinking = False if self.disable_inspiration_lm else True
        use_cot = False if self.disable_inspiration_lm else True

        return AceStepGenerationRequest(
            caption=caption,
            lyrics=lyrics,
            bpm=int(direction.bpm),
            keyscale=direction.keyscale,
            timesignature=str(direction.timesignature),
            vocal_language=direction.language,
            duration=duration,
            seed=int(seed),
            thinking=thinking,
            use_cot_metas=use_cot,
            use_cot_caption=use_cot,
            use_cot_lyrics=False,
            use_cot_language=use_cot,
            instrumental=False,
            inference_steps=self.inference_steps,
            guidance_scale=self.guidance_scale,
            task_type="text2music",
            section_tag_strategy=strategy.value,
            timeline_name=timeline.name,
            metadata={
                "inspiration_lm": "OFF" if self.disable_inspiration_lm else "ON",
                "inspiration_lm_disable_method": (
                    "GenerationParams.thinking=False and use_cot_*=False; "
                    "llm_handler left uninitialized / ACESTEP_INIT_LLM=false"
                ),
                "provider_neutral_timeline": timeline.to_dict(),
                "creative_direction": direction.to_dict(),
                "story_lyric_body": story_lyric_body(story),
            },
        )
