"""Unit tests for the experimental ACE-Step narrative adapter.

These tests do not require audio generation.
"""

from __future__ import annotations

import json
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


@pytest.fixture
def story():
    return load_story(POC_ROOT / "inputs" / "story.txt")


@pytest.fixture
def direction():
    return load_creative_direction(POC_ROOT / "inputs" / "creative_direction.json")


@pytest.fixture
def timeline_a():
    return load_timeline(POC_ROOT / "inputs" / "timeline_a.json")


@pytest.fixture
def timeline_b():
    return load_timeline(POC_ROOT / "inputs" / "timeline_b.json")


def test_timeline_a_compiles(story, direction, timeline_a):
    adapter = AceStepNarrativeAdapter(disable_inspiration_lm=True)
    req = adapter.compile(story, direction, timeline_a, seed=42)
    assert req.caption
    assert req.lyrics
    assert req.duration == direction.duration_seconds
    assert req.thinking is False
    assert req.use_cot_caption is False
    assert req.use_cot_metas is False


def test_timeline_b_compiles(story, direction, timeline_b):
    adapter = AceStepNarrativeAdapter(disable_inspiration_lm=True)
    req = adapter.compile(story, direction, timeline_b, seed=42)
    assert req.caption
    assert req.lyrics
    assert "[Breakthrough" in req.lyrics or "Breakthrough" in req.caption


def test_same_story_identical_lyric_body(story, direction, timeline_a, timeline_b):
    adapter = AceStepNarrativeAdapter(
        section_tag_strategy=SectionTagStrategy.NATURAL_TAGS,
        disable_inspiration_lm=True,
    )
    a = adapter.compile(story, direction, timeline_a, seed=1)
    b = adapter.compile(story, direction, timeline_b, seed=1)
    body_a = extract_lyric_body(a.lyrics)
    body_b = extract_lyric_body(b.lyrics)
    expected = story_lyric_body(story)
    assert body_a == expected
    assert body_b == expected
    assert body_a == body_b


def test_caption_only_preserves_identical_lyrics(story, direction, timeline_a, timeline_b):
    adapter = AceStepNarrativeAdapter(
        section_tag_strategy=SectionTagStrategy.CAPTION_ONLY,
        disable_inspiration_lm=True,
    )
    a = adapter.compile(story, direction, timeline_a, seed=1)
    b = adapter.compile(story, direction, timeline_b, seed=1)
    assert a.lyrics == b.lyrics
    assert "[" not in a.lyrics  # no section tags


def test_provider_independent_concepts_preserved(timeline_a, timeline_b):
    data = timeline_a.to_dict()
    assert "segments" in data
    assert data["segments"][0]["narrative_intent"]
    assert "energy" in data["segments"][0]
    # No ACE-Step field names on the provider-neutral object.
    dumped = json.dumps(data)
    assert "keyscale" not in dumped
    assert "timesignature" not in dumped
    assert "caption" not in dumped


def test_ace_step_specific_output_only_from_adapter(story, direction, timeline_a):
    adapter = AceStepNarrativeAdapter(disable_inspiration_lm=True)
    req = adapter.compile(story, direction, timeline_a, seed=7)
    params = req.generation_params_dict()
    for key in (
        "caption",
        "lyrics",
        "bpm",
        "keyscale",
        "timesignature",
        "vocal_language",
        "duration",
        "seed",
        "thinking",
    ):
        assert key in params
    # Provider-neutral timeline still available in metadata, not as ACE params.
    assert "segments" not in params
    assert "provider_neutral_timeline" in req.metadata


def test_timelines_compile_to_different_provider_inputs(
    story, direction, timeline_a, timeline_b
):
    adapter = AceStepNarrativeAdapter(disable_inspiration_lm=True)
    a = adapter.compile(story, direction, timeline_a, seed=42)
    b = adapter.compile(story, direction, timeline_b, seed=42)
    assert a.caption != b.caption
    assert a.lyrics != b.lyrics  # tags/structure differ even if body matches
    assert a.timeline_name != b.timeline_name


def test_unrelated_musical_constraints_remain_identical(
    story, direction, timeline_a, timeline_b
):
    adapter = AceStepNarrativeAdapter(disable_inspiration_lm=True)
    a = adapter.compile(story, direction, timeline_a, seed=99)
    b = adapter.compile(story, direction, timeline_b, seed=99)
    for field in (
        "bpm",
        "keyscale",
        "timesignature",
        "vocal_language",
        "duration",
        "seed",
        "thinking",
        "use_cot_metas",
        "use_cot_caption",
        "inference_steps",
        "guidance_scale",
        "task_type",
    ):
        assert getattr(a, field) == getattr(b, field)


def test_natural_tags_vs_caption_only_differ(story, direction, timeline_a):
    tagged = AceStepNarrativeAdapter(
        section_tag_strategy=SectionTagStrategy.NATURAL_TAGS,
        disable_inspiration_lm=True,
    ).compile(story, direction, timeline_a, seed=1)
    plain = AceStepNarrativeAdapter(
        section_tag_strategy=SectionTagStrategy.CAPTION_ONLY,
        disable_inspiration_lm=True,
    ).compile(story, direction, timeline_a, seed=1)
    assert "[" in tagged.lyrics
    assert "[" not in plain.lyrics
    assert extract_lyric_body(tagged.lyrics) == extract_lyric_body(plain.lyrics)
    assert tagged.caption != plain.caption
