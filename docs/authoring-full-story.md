# Authoring a full interactive Flam story (fw 2.4.2)

**Audience:** Story authors · Flam builders · collaborators  
**Scope:** Packaging / interop only. No CFW. Original or dummy assets only — never catalog prose or audio.  
**Firmware:** stock **2.4.2**  
**Proven references:** [`stories/lost-button/`](../stories/lost-button/) · [`stories/kipodi-learns-to-ride-a-bike/`](../stories/kipodi-learns-to-ride-a-bike/)  
**Deep RE:** [`map-backpack-re.md`](map-backpack-re.md) · [`flam-fw2-technical-guide.md`](flam-fw2-technical-guide.md) · [`fw2-key-wrap.md`](fw2-key-wrap.md)

---

## 0. One-line contract

Stories are Lua modules under `Global.load_module`, assets under `img/*.lif` + `sounds/*.mp3` (+ `.mp3map`), build → `.plain.pk` → `flamtool/pack.py`. Audio is **single-track** and delayed ~500 ms; **priority cut-in** is required on scene enter; **do not stop-all in `clean()`** during `load_module` transitions.

---

## 1. Module shell (non-negotiable)

```lua
function setup()
    Global = require("global")   -- GLOBAL, not local
    Global.init()
    Global.setBackToLibrary()
    Global.load_module("my_story", "1_0_0").create({})
end
```

- No top-level `require` in `main.lua`.
- Game lives in `create` / `clean` modules. Prefer whitelist: `lv.*`, `Global.*`, `audio.*` (+ firmware globals: `window`, `document`, `state`, `goto_library`, `back_callback`, `context_menu`).
- Prefer shipped runtime modules (`list-choice_1_0_0`, `title-card`, `chapterView`, …) over inventing host APIs.
- Build toolchain: [flam-player `skills/flam-homebrew`](https://github.com/scarlaty/flam-player/tree/main/skills/flam-homebrew).

---

## 2. Audio lifecycle (hard rules)

### API

```lua
Global.requestAudioPlay({
    path = "morning.mp3",       -- basename under sounds/
    priority = true,            -- MUST be true when entering a beat / cutting in
    showPause = false,          -- optional
})

Global.requestAudioStop()                 -- safe in clean() (list-choice style)
Global.requestAudioStop(true)             -- instant stop, keep pending
Global.requestAudioStop(true, true)       -- instant + clear pending — library exit / hard mute ONLY
```

### Do

| Situation | Rule |
|-----------|------|
| Entering a narration beat | `priority = true` |
| `list-choice` title / focus | keep default `forcePlay = true` |
| Scene→scene via `load_module` | next `create` uses `priority = true`; previous `clean` must **not** clear pending |
| Play order | queue `requestAudioPlay` **before** LIF / UI work |
| Title screen | non-nil audible path (short `tone.mp3` is enough) |
| Exit to library | `requestAudioStop(true, true)` then `goto_library()` |

### Don’t

```lua
-- BAD: races next requestAudioPlay
function scene.clean()
    Global.requestAudioStop(true, true)
end

-- GOOD
function scene.clean()
    Global.requestAudioStop()   -- no instant, no clear
    -- tear down UI/timers only
end
```

Never call raw `audio.load` while status ≠ `"stop"` (device hard freeze). Prefer `Global.requestAudioPlay`.

### Encoding

| Spec | Expectation |
|------|-------------|
| Container | MPEG-1 Layer III `.mp3` |
| Rate / channels | **44100 Hz**, **mono** preferred for VO |
| Bitrate | **96–128 kb/s** CBR (`libmp3lame`) |
| Sidecar | every file needs `sounds/<name>.mp3map` (build generates) |
| Choice rows | ship `silent.mp3` (+ map) for mute rows |

```bash
ffmpeg -y -i in.wav -ar 44100 -ac 1 -codec:a libmp3lame -b:a 128k out.mp3
```

---

## 3. Session backpack (proven)

There is **no** host `backpack.*` API. Use an in-memory table on `Global.*` and present it with `list-choice` (Lost Button) or a custom scene info line (Kipodi).

```lua
local LB = {}
Global.LB = LB

function LB.show_backpack()
    local choices = {}
    if LB.has_button then
        choices[1] = {
            label = "Shiny button",
            img = "button.lif",
            audio = "tone.mp3",
            cb = function() end,
        }
    else
        choices[1] = {
            label = "Backpack is empty",
            img = "empty.lif",
            audio = "silent.mp3",
            cb = function() end,
        }
    end
    Global.load_module("list-choice", "1_0_0").create({
        title = "Backpack",
        choices = choices,
    })
end
```

**Do not** write backpack into `state` for short stories (relaunch black-screen risk). Catalog-style `state.inventory` + `collection` / `detail` remains **partial / not homebrew-proven** — see [`map-backpack-re.md`](map-backpack-re.md).

Kipodi bike variant: `Global.KB.backpack` / `KB.have` + hub rows for Backpack / Chapters.

---

## 4. Chapter map (proven)

There is **no** `Map.create`. Real stack (Chapter Map Canary + Kipodi bike):

```lua
-- setup()
Global.isMultiBranches = false
Global.progression.create({
    totalChapters = 5,
    backBehavior = function() /* return to hub */ end,
    chapterViewLabel = "Chapters",
})

-- on entering a chapter beat
Global.progression.setProgression({
    currentFunction = "ChapterOne",
    ischapter = true,
    chapterData = {
        label = "Hanukkah morning",
        cb = "ChapterOne",   -- string: _G[cb]() when single-branch
        img = "ch1_tile.lif",
        audio = "ch1_name.mp3",
        order = 1,
    },
})

-- open product Map
Global.progression.displayChapters(true)
```

- Confirm dialog in shipped runtime is **French** (`Reprendre l'histoire à partir de ce chapitre ?`).
- Prefer **no** `chapterData.inventory` unless you intentionally merge into `state.inventory` (hazardous).
- Kipodi restores backpack from each chapter’s `carry` list in the session table instead.

---

## 5. Choices

```lua
Global.load_module("list-choice", "1_0_0").create({
    title = "Which way?",
    choices = {
        {
            label = "Left",
            img = "left.lif",      -- required string
            audio = "silent.mp3",  -- required string
            cb = function()
                Global.load_module("next_beat", "1_0_0").create({})
            end,
        },
    },
})
```

Every row needs string `img` + `audio`. Latin-1 only on device strings (no emoji / curly quotes).

---

## 6. In-story mini-game pattern

Kipodi bike embeds **Box Breaker** as a `create`/`clean` module (`kipodi_breakout_1_0_0`) loaded from a beat with `kind = "minigame"`:

- Win → story beat (`you_did_it`)
- Lose → retry beat; after `max_tries` (2) → assist beat (GaGa help) then continue
- Game audio uses the same priority / clean rules as scenes
- Keep collision / paddle logic inside the module; return to story via `Global.load_module` callbacks — do not invent host game APIs

Use this as a template for other short LVGL games inside a narrative pack.

---

## 7. Art gates

- Full-screen art: **320×212** (or 320×240 centered in the 212-high window)
- Thumb: **104×136** portrait → build pipeline
- Deliver PNG → build to `.lif`; Lua loads `Global.load_image("file.lif")`
- High contrast at 320; no tiny baked-in text; original / dummy only

---

## 8. Mint (fw 2.x)

See [`fw2-key-wrap.md`](fw2-key-wrap.md) and [`author-mint-play.md`](author-mint-play.md).

```text
key = SNU32 = (SNU24 || SNU24)[0:32]
```

Cipher `info` and `*.lsf` with AES-128-CBC under `.mdf` C0/C1; leave media plain; append UUID to `etc/library/list`; delete `usr/0/library.cache`.

```bash
python flamtool/pack.py "$FLAM_ROOT" story.plain.pk
sync
```

---

## 9. Ship checklist

### Content / features

- [ ] 100% original (or dummy) prose, art, audio — no catalog assets  
- [ ] Latin-1 on-device strings; title ≤ ~40 chars  
- [ ] “Backpack” = session table + UI, not a fake host call  
- [ ] “Map” omitted **or** `chapterView` + `Global.progression`  

### Lua / audio

- [ ] `setup()` assigns **global** `Global = require("global")`  
- [ ] Interactive screens are `create`/`clean` via `Global.load_module`  
- [ ] Narration / title: `priority = true` (or list-choice `forcePlay`)  
- [ ] `clean()` does **not** call `requestAudioStop(true, true)` on scene transitions  
- [ ] Library exit stops audio explicitly, then `goto_library()`  
- [ ] `requestAudioPlay` before heavy `load_image` / UI  
- [ ] Title screen has audible audio  
- [ ] Every `list-choice` row has string `img` + `audio`  

### Assets / build

- [ ] All Lua `"*.mp3"` / `"*.lif"` literals exist under `sounds/` / `img/`  
- [ ] VO is 44.1 kHz mono CBR ~128k; matching `.mp3map`  
- [ ] `flam_check` → **zero `[ERR]`**; simulator `--strict` if available  
- [ ] Output `*.plain.pk` ready to mint  

### Device play-test

- [ ] Library title readable  
- [ ] Title audio without pressing Begin  
- [ ] First beat VO plays; Next cuts in  
- [ ] Choices + backpack + chapters (if claimed)  
- [ ] Exit → relaunch ×2  
- [ ] Progress % often ~1% on homebrew — do not block ship  

---

## 10. Feature status (honest)

| Feature | Status | Pattern |
|---------|--------|---------|
| Choices | **Known** | `list-choice_1_0_0` |
| Session backpack | **Known** | `Global.*` table + list-choice / custom UI |
| Chapter map | **Known** | `Global.progression` + `chapterView` |
| In-story mini-game | **Known** (Kipodi bike) | Story module + load_module return |
| Catalog `state.inventory` | **Partial** | Avoid until USB-proven |
| Lateral `context_menu` | **Partial** | Real host API; homebrew not device-proven here |
| Library progress bar | **Partial** | Often stuck ~1% — ship anyway |

Never claim fake `Map.*` / `backpack.*` host APIs.

---

*Packaging/interop only. Dummy or original assets in examples. No CFW. No official catalog content.*
