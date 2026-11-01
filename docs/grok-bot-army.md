# Grok bot army — full-length Flam story

Hand these roles to separate Grok bots. Their combined output must be a **device-ready** tree that this Project will later `flam_check` → `flamtool/pack.py` → Flam fw **2.4.2**.

Proven loop: [Lost Button](lost-button.md) · mint: [fw2-key-wrap](fw2-key-wrap.md) · pipeline: [ai-flam-pipeline](ai-flam-pipeline.md) · play: [author-mint-play](author-mint-play.md).

## Known device quirk (do not ignore)

Library / in-story **progress stays ~1%** even after finishing (seen on Lost Button). Bots must still wire `progression` / chapter saves if the API allows, but **do not block ship** on a perfect progress bar until we fix it. Prefer `progression.create` / chapter markers if documented in flam-homebrew; record expected progress events in the QA bot’s checklist.

## Shared constraints (paste into EVERY bot)

```
TARGET: Lunii Flam fw 2.4.2, homebrew .plain.pk → pack.py mint (key=SNU32, cipher info/lsf with .mdf C0/C1).
CONTENT: 100% original. No Emily/Lunii catalog text, art, or audio.
RUNTIME: Lua 5.4 + LVGL via flam-homebrew. API whitelist ONLY: lv.*, Global.*, audio.*
FORBIDDEN: io, os, debug, network, filesystem, top-level require outside setup().
SCREEN: 320x240; play area ~320x212. Fonts Latin-1 only (no emoji, no curly quotes, no fancy dashes).
AUDIO: one track at a time; audio.load only when audio.get_status() == "stop". Provide .mp3 + .mp3map.
IMAGES: PNG/JPEG sources 320x240 → build to .lif; load via Global.load_image("file.lif") under img/.
STRUCTURE:
  main.lua calls setup(); Global = require("global") (GLOBAL, not local);
  game = Global.load_module("modname", "1_0_0").create({}); clean() destroys all.
  Modules: create(opts) / clean(); wheel keys 19/20; click lv.EVENT_CLICKED;
  add UI to document; lv.group.set_editing(document, true).
PACK: uuid.bin, info.plain, version, main.lua, script/<mod>_<ver>.lua, img/*, sounds/*.
GATE: flam_check.py must report zero [ERR]. Simulator --strict before device.
OUTPUT LANGUAGE: English Latin-1 for on-device strings unless owner says otherwise.
```

Owner prompt (filled by human once):

```
TITLE:
AGE BAND:
TONE:
LENGTH TARGET: (e.g. 15–25 scenes, ~8–12 min audio)
FEATURES REQUIRED: choices, backpack, [map?], [traits?]
PREMISE / MUST-INCLUDE BEATS:
HARD NO: (topics, tone, IP)
VOICE STYLE: (warm narrator / kid-safe / …)
ART STYLE: (flat illustration, rainy night, …)
```

---

## Bot 1 — Showrunner (plot architect)

**Job:** Turn the owner prompt into a complete interactive design that fits Flam.

**You produce:**
1. `story-bible.md` — premise, cast, tone, themes (short).
2. `beat-graph.json` — every scene node with: `id`, `type` (`narration|choice|inventory|map|ending`), `text_on_screen` (≤2 short lines), `narration_script` (spoken, timed ~10–40s), `choices[]` `{label, goto, effects}`, `grants[]` / `requires[]` for backpack, `image` basename, `audio` basename.
3. `feature-map.md` — which Flam features each beat uses.
4. `length-budget.md` — scene count, total narration words, estimated minutes.

**Rules:** Max branching you can QA (prefer 1–2 meaningful branches that rejoin). Backpack items ≤5. No dead ends without ending card. Every path reachable. Latin-1 only in on-screen labels.

**Handoff to:** Bot 2 (dialogue polish), Bot 3 (Lua), Bot 4 (art list), Bot 5 (voice list).

---

## Bot 2 — Dialogue & UX writer

**Job:** Polish all player-facing strings and narration for device constraints.

**You take:** `beat-graph.json`, `story-bible.md`.

**You produce:**
1. Updated `beat-graph.json` with final `text_on_screen` and `narration_script`.
2. `copy-sheet.csv` — columns: `beat_id,field,text,char_count` (flag anything >~80 chars on-screen).
3. `choice-labels.md` — wheel-friendly short labels (≤24 chars).

**Rules:** Latin-1. No spoilers in library title. Title ≤ ~40 chars. Narration should pause naturally for clicks. Keep/leave and left/right patterns must stay clear.

**Handoff to:** Bot 3, 5.

---

## Bot 3 — Flam Lua engineer

**Job:** Implement a flam-homebrew-compliant Lua project that matches the beat graph.

**You take:** final `beat-graph.json`, feature map, Lost Button as reference pattern.

**You produce:**
```
project/
  main.lua
  script/<mod>_1_0_0.lua   # and extra modules if needed
  info.plain                 # title + subtitle lines per fw2 info format
  version                    # e.g. 1
  assets-manifest.json       # exact img/ and sounds/ basenames required
```

**Rules:** Exact API whitelist. `Global.load_module` module pattern. `create`/`clean`. Session backpack in Lua tables (and `progression` if using saves). No missing asset string literals. Comment each beat_id in code.

**Handoff to:** Bot 6 (integrate assets), Bot 7 (QA).

---

## Bot 4 — Art director (Grok Imagine)

**Job:** Spec and generate every visual.

**You take:** beat graph + art style from owner prompt.

**You produce:**
1. `art-prompts.json` — one prompt per image: `{file, prompt, negative, size:"320x240", notes}`.
2. Generated PNGs named exactly as in manifest (`thumb.png`, `bus_stop.png`, …).
3. `art-qa.md` — checklist: readable at 320×240, high contrast, no tiny text in image, Latin-1 safe, no watermark.

**Rules:** Flat/clear shapes for small screen. Thumb must read as cover. Avoid photoreal faces if muddy at 320. Export RGB PNG.

**Handoff to:** Bot 6 (PNG→LIF).

---

## Bot 5 — Voice director (open-source TTS)

**Job:** Spec and generate all narration/SFX (not ElevenLabs — OSS stack).

**Recommended OSS stack (bot may adjust if better):**
- TTS: **Piper**, **Coqui XTTS**, or **MeloTTS** (pick one; document voice id).
- Optional SFX: short OSS tones / self-made; keep tiny.
- Normalize: ffmpeg → mono **44100 Hz** MP3, loudness roughly consistent.

**You take:** `copy-sheet` narration scripts + voice style.

**You produce:**
1. `voice-plan.json` — `{file, script, voice, speed, emotion}`.
2. `sounds/*.mp3` exact basenames from manifest.
3. `sounds/*.mp3map` if your pipeline requires them (match flam-homebrew / build scripts).
4. `silent.mp3` (+ map) for choice rows if needed.
5. `voice-qa.md` — peak levels, max duration per file, Latin-1 scripts only.

**Rules:** One track at a time on device. Prefer shorter clips; long monologues → split beats. No copyrighted music.

**Handoff to:** Bot 6.

---

## Bot 6 — Asset integrator / build tech

**Job:** Assemble the final project tree and run build tools.

**You take:** Lua from Bot 3, PNG from Bot 4, MP3 from Bot 5.

**You produce:**
1. Complete project directory ready for `flam_build.py`.
2. Convert images with project `lif.py` / build pipeline → `img/*.lif`.
3. Run `flam_build.py` → `_out/<title>.plain.pk`.
4. Run `flam_check.py` → **zero [ERR]** (fix until green).
5. Optional simulator `--strict`.
6. `build-report.md` — commands, versions, pk path, UUID.

**Handoff to:** Bot 7, then human/Cursor pack to device.

---

## Bot 7 — Device QA lead

**Job:** Define and (with owner) execute the acceptance test.

**Checklist (must pass):**
- [ ] Library title readable (not garbage)
- [ ] Opens past “loading”
- [ ] Every branch playable end-to-end
- [ ] Backpack grant/require works
- [ ] Audio plays; no stuck load when status ≠ stop
- [ ] Exit → library → relaunch ×2
- [ ] Progress bar noted (known 1% quirk) — log actual % if any change
- [ ] No crash / black screen

**You produce:** `qa-report.md` with pass/fail and repro notes.

---

## Bot 8 — Continuity / lore guard (optional but useful for long stories)

**Job:** Catch contradictions across bots.

**You produce:** `continuity-report.md` — item IDs, flags, dead links in beat graph, missing assets, tone breaks.

---

## Orchestration order

```
Owner prompt
  → Bot1 Showrunner
  → Bot2 Writer ─┬→ Bot3 Lua
                 ├→ Bot4 Art (parallel)
                 └→ Bot5 Voice (parallel)
                      → Bot6 Integrate/build
                      → Bot7 QA
Owner / Cursor: flamtool pack.py → Flam
```

## What to hand back to this Project (Cursor) for import

A single folder or zip:

```
<story>/
  _out/<story>.plain.pk          # preferred
  OR full source tree + build scripts
  build-report.md
  qa-report.md (if any)
  beat-graph.json
```

Then say: “pack this to Flam” — we run `pack.py`, sync, eject, you play-test.

## Progress bar follow-up (engineering, not Grok)

Investigate Flam `progression` / `.prog` / chapter saves vs library % for homebrew. Track separately; do not block army output.
