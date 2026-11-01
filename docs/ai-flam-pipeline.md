# AI Flam story pipeline (scaffold)

Goal: turn a short brief into an original Flam-native pack that builds, packs, and plays on fw 2.4.2 — without ripping catalog content or modifying firmware.

Mint/play mechanics: [`author-mint-play.md`](author-mint-play.md). Runtime sketch: [`flam-native-lsf.md`](flam-native-lsf.md) + flam-homebrew `references/lua-api.md`.

## Pipeline stages

```
brief → generate Lua modules + asset list → flam_check → pack → device verify
```

| Stage | Input | Output | Gate |
|---|---|---|---|
| **1. Brief** | Age band, tone, 1–3 beats, which Flam features to exercise | Structured brief (JSON or markdown) | Owner OK on theme / length |
| **2. Generate** | Brief + API allowlist + module templates | `main.lua`, `script/<mod>_<ver>.lua`, asset list (`img/`, `sounds/`) | No `io`/`os`/`debug`; Latin-1 text; module `create`/`clean` contract |
| **3. Assets** | Asset list | LIFF via `lif.py` / PNG→build; short MP3 + `.mp3map`; `silent.mp3` for choice rows | Basenames match `Global.load_image` / `audio` literals |
| **4. Check** | Project tree | `flam_build.py` → `.plain.pk`; `flam_check.py` zero `[ERR]` | Fail closed on missing runtime/assets |
| **5. Pack** | `.plain.pk` + mounted Flam | `flamtool/pack.py` | Fresh UUID; cache deleted |
| **6. Device** | Power-cycle | Readable title; play; exit→relaunch×2 | Mark features **device-proven** only after this |

Host commands and paths: [`author-mint-play.md`](author-mint-play.md).

### Brief schema (minimal)

```yaml
title: string          # Latin-1, library line
uuid_seed: string      # unique per pack
module: string         # e.g. lost_button
version: "1_0_0"
beats:                 # 2–5 short nodes
  - id: start
    text: ...
    choices: [{label, goto, grant?}]
features: [choices, backpack]   # subset of map below
assets:
  images: [thumb, scene_a, …]
  sounds: [silent, narr_start, …]
constraints:
  max_screens: 4
  no_state_writes: true          # homebrew relaunch-safe default
```

### Generator rules (non-negotiable)

- `setup()` only: `Global = require("global")` (global), then `Global.load_module(...).create({})`
- Game logic in one primary module with `create` / `clean`; timers deleted in `clean`
- Wheel: `EVENT_KEY` 19/20 + `EVENT_CLICKED` for click; container in `document` + `set_editing`
- Prefer shipped runtime modules (`list-choice_*`, `dialog*`, …) over inventing host APIs
- Original prose/art/audio only — never Emily or other catalog assets

## Feature → API map

Provenance: public Flam.RE / [`flam-native-lsf.md`](flam-native-lsf.md) identifiers + flam-homebrew runtime under `~/flam-re/flam-player/skills/flam-homebrew/assets/runtime/`.

| Flam feature | Documented API / modules | Device-proven (this unit) | Still to prove |
|---|---|---|---|
| **Boot / module shell** | `setup`, `Global`, `Global.load_module`, `Global.init`, `create`/`clean` | Yes — hello + `casse-briques` | — |
| **Wheel / click** | `lv.EVENT_KEY` (19/20), `lv.EVENT_CLICKED`, `lv.group.set_editing(document,true)` | Yes — `casse-briques` | — |
| **Images** | `Global.load_image("x.lif")`, LIFF plain under `img/` | Yes (homebrew + official layout) | Complex panoramic / stress modules |
| **Audio** | `audio.load` / `play` / `get_status`; single track; load only when `"stop"` | Partial — patterns from homebrew docs; `casse-briques` path | Multi-beat narration chains on-device for *our* stories |
| **Choices (list)** | `list-choice_1_0_0`, `list-choice-circular`; entries need `audio` string (use `silent.mp3`) | Pack minted (*Lost Button*); **play-test pending** | Confirm on-device after power-cycle |
| **Choices (image)** | `image-choice_1_0_0`, `image-Button` | Filenames + public fragments | Device with original art |
| **Dialogs** | `dialog`, `dialog_1_0_0`, `dialog-interactive`, `modal-info_0_9_0` | Runtime shipped | Device in original pack |
| **Inventory / backpack** | Session bag on `Global.LB` + `list-choice` UI (*Lost Button*); catalog `state.inventory` / `collection` still heavier | Minted session backpack (no `state` writes); **play-test pending** | Optional later: safe `state` / collection path |
| **Map / chapters** | `progression` / `progressionManager`, `chapterView`, `Global.loadBranch`, `state.visited_funs` | Names + Emily filenames only | Minimal chapter map in original pack |
| **Context / lateral menu** | `context_menu.set_entries` | Documented | Device in original pack |
| **Title chrome** | `title-card`, `title-screen` | Runtime shipped; *Lost Button* ending uses `title-card` (minted; play-test pending) | Confirm ending card on-device |
| **Save / relaunch** | Prefer **no** `state` writes for tiny games; staged back → title → `goto_library` | Relaunch pitfalls device-proven (casse-briques class) | Story-style `progression.save("chaps")` safely |

Legend: **device-proven** = observed working on this 2.4.2 unit with personal mint. **Still to prove** = APIs known from docs/runtime but not yet validated end-to-end in an original pack here.

## First AI-assisted story brief (proposed)

**Lost Button** — done (minted 2026-11-01): rainy bus stop → left/right puddle → backpack button → keep/leave → title-card. See [`lost-button.md`](lost-button.md). Owner device play-test still open before marking features **device-proven**.

## Out of scope for the pipeline

- CFW, SWD, or recovering the device key for official decryption  
- Shipping or transforming Emily / paid catalog media  
- Classic STUdio→Lunii.QT packs (blocked on this fw for Flam-native features)
