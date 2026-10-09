"""Phase 2 adapter strategy tests (no audio generation)."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

POC_ROOT = Path(__file__).resolve().parents[1]
SRC = POC_ROOT / "src"
sys.path.insert(0, str(SRC))

from ace_step_adapter import (  # noqa: E402
    AceStepNarrativeAdapter,
    SectionTagStrategy,
    extract_lyric_body,
    story_lyric_body,
)
from narrative_music import (  # noqa: E402
    load_creative_direction,
    load_story,
    load_timeline,
)
from phase2_experiment import compile_phase2_pair, expected_phase_windows  # noqa: E402


@pytest.fixture
def story():
    return load_story(POC_ROOT / "inputs" / "story.txt")


@pytest.fixture
def direction():
    return load_creative_direction(POC_ROOT / "inputs" / "creative_direction.json")


@pytest.fixture
def timeline_a():
    return load_timeline(POC_ROOT / "inputs" / "phase2_timeline_a.json")


@pytest.fixture
def timeline_b():
    return load_timeline(POC_ROOT / "inputs" / "phase2_timeline_b.json")


def test_phase2_timelines_load(timeline_a, timeline_b):
    assert timeline_a.name == "phase2_intimate_arc"
    assert timeline_b.name == "phase2_transformation_arc"
    assert any(s.role == "breakthrough" for s in timeline_b.segments)
    assert any(s.role == "climax" for s in timeline_b.segments)
    assert abs(timeline_a.total_duration_seconds - 48.0) < 1e-6
    assert abs(timeline_b.total_duration_seconds - 48.0) < 1e-6


def test_narrative_tags_strategy(story, direction, timeline_b):
    req = AceStepNarrativeAdapter(
        section_tag_strategy=SectionTagStrategy.NARRATIVE_TAGS,
        disable_inspiration_lm=True,
    ).compile(story, direction, timeline_b, seed=42)
    assert "[Breakthrough" in req.lyrics
    assert "[Climax" in req.lyrics
    assert "[Chorus" not in req.lyrics


def test_song_tags_strategy_is_adapter_only(story, direction, timeline_b):
    req = AceStepNarrativeAdapter(
        section_tag_strategy=SectionTagStrategy.SONG_TAGS,
        disable_inspiration_lm=True,
    ).compile(story, direction, timeline_b, seed=42)
    # Conventional song labels appear in lyrics as adapter compilation.
    assert "[Verse" in req.lyrics or "[Intro" in req.lyrics
    assert "[Chorus" in req.lyrics
    assert "[Outro" in req.lyrics
    # Provider-neutral timeline metadata still uses narrative roles.
    roles = [s["role"] for s in req.metadata["provider_neutral_timeline"]["segments"]]
    assert "breakthrough" in roles
    assert "chorus" not in roles


def test_three_strategies_differ_on_same_timeline(story, direction, timeline_b):
    bodies = []
    captions = []
    for strategy in (
        SectionTagStrategy.NARRATIVE_TAGS,
        SectionTagStrategy.SONG_TAGS,
        SectionTagStrategy.CAPTION_ONLY,
    ):
        req = AceStepNarrativeAdapter(
            section_tag_strategy=strategy,
            disable_inspiration_lm=True,
        ).compile(story, direction, timeline_b, seed=7)
        bodies.append(extract_lyric_body(req.lyrics))
        captions.append(req.caption)
        assert req.thinking is False
    assert bodies[0] == bodies[1] == bodies[2] == story_lyric_body(story)
    assert captions[0] != captions[2]
    assert captions[0] != captions[1]


def test_expected_phase_windows_cover_duration(timeline_b):
    windows = expected_phase_windows(timeline_b.to_dict(), 48.0)
    assert windows[0]["start_s"] == 0.0
    assert abs(windows[-1]["end_s"] - 48.0) < 1e-6
    bt = next(w for w in windows if w["role"] == "breakthrough")
    assert bt["start_s"] < bt["end_s"]


def test_compile_phase2_pair_controls_constant():
    compiled = compile_phase2_pair(
        strategy=SectionTagStrategy.NARRATIVE_TAGS, seed=123
    )
    a = compiled["params_a"]
    b = compiled["params_b"]
    for key in ("bpm", "keyscale", "timesignature", "vocal_language", "duration", "seed"):
        assert a[key] == b[key]
    assert a["caption"] != b["caption"]
