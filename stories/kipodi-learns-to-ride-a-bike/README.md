# Kipodi learns to ride a bike

Original Flam homebrew interactive story (English). Open-source example of a **full** pack on stock fw **2.4.2**: narration choices, session backpack, chapter map, and an in-story **Box Breaker** mini-game.

**License:** original content by Yariminal — free to study, fork, and remix for personal Flam homebrew (keep catalog assets out of your forks).

## Synopsis (six beats)

1. **Hanukkah morning** — Kipodi gets a shiny new bike and yellow helmet; rides at the park; shares a goal (or takes a slow lap).
2. **Rock** — a bump snaps a stabilizer; GaGa walks him home.
3. **Shed vs house** — garden shed is locked without the key; house leads to a game find.
4. **Box Breaker** — break the boxes; **2 losses** unlock GaGa’s help path, then the win beat.
5. **Key / toolbox / stabilizers** — mantle key → open shed → toolbox → both stabilizers off.
6. **Two wheels** — back to the park; wobble choices (look ahead / pedal slow) → successful ride → bedtime.

**Scale:** 25 scenes · ~9 minutes narration · 5 chapter-map chapters.  
**Art note:** v2 uses a darker paddle/ball for Box Breaker.

## Device / sim status

| Check | Result |
|-------|--------|
| Simulator routes | 9 routes OK |
| Device launch | OK |
| Chapter map tiles | OK (confirm dialog French from shipped runtime) |
| Features | Session backpack · `Global.progression` + `chapterView` · embedded breakout |

Screenshots: [`docs/media/kipodi-bike-*.png`](../../docs/media/) (and art sheet `.jpg`).

## What’s in this folder

| Path | Role |
|------|------|
| `main.lua` | Bootstrap + `ChapterOne`…`ChapterFive` jump hooks |
| `script/kipodi_bike_1_0_0.lua` | Orchestrator (hub, backpack, chapters, beat runner) |
| `script/kipodi_scene_1_0_0.lua` | Narration / choice scene shell (audio priority pattern) |
| `script/kipodi_breakout_1_0_0.lua` | Box Breaker mini-game |
| `script/kipodi_data.lua` | Beat graph + chapter table (25 beats) |
| `img/*.lif` | Story art (built LIFF) |
| `sounds/*.mp3` (+ `.mp3map`) | Narration / SFX |
| `flam.json` | Title / UUID seed / module metadata |
| `dist/kipodi-learns-to-ride-a-bike.plain.pk` | **Ready to mint** (~11 MB; includes runtime modules) |

### Gap: no separate PNG / beat-graph source tree

Editable **Lua + built LIF/MP3** are here. The upstream `story/beat-graph.json` / PNG pipeline used to generate `kipodi_data.lua` was **not** found beside this pack — rebuild from scratch means editing the Lua data + assets, or unpacking/replacing files inside the `.plain.pk`. The shipped pack is the supported “drop on device” form.

Runtime UI modules (`global.lua`, `list-choice_1_0_0`, `chapterView`, …) live **inside** the `.plain.pk` (from flam-homebrew build), not duplicated as loose sources here.

## Pack to a Flam

```bash
# from repo root, Flam mounted at $FLAM_ROOT
python flamtool/pack.py "$FLAM_ROOT" \
  stories/kipodi-learns-to-ride-a-bike/dist/kipodi-learns-to-ride-a-bike.plain.pk
sync
```

See [`docs/author-mint-play.md`](../../docs/author-mint-play.md) and [`docs/authoring-full-story.md`](../../docs/authoring-full-story.md).

## Chapters (map tiles)

| # | Label | Start beat | Carry (backpack on jump) |
|---|-------|------------|---------------------------|
| 1 | Hanukkah morning | `morning` | — |
| 2 | At the park | `park` | helmet |
| 3 | The walk home | `walk_home` | helmet |
| 4 | The shed | `shed_open` | helmet, key |
| 5 | Two wheels | `back_to_park` | helmet, key, toolbox |
