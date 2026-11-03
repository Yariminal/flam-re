# Map · Backpack · interactive features — RE (fw 2.4.2 homebrew)

**Audience:** Flam builders · story authors  
**Scope:** Packaging / interop only. No CFW. No catalog prose/audio retention.  
**Firmware:** 2.4.2  
**Sources:** flam-player runtime Lua, Lost Button + Kipodi packs, Flam.RE public dumps / plain fragments, [`authoring-full-story.md`](authoring-full-story.md), [`flam-native-lsf.md`](flam-native-lsf.md), [`flam-fw2-technical-guide.md`](flam-fw2-technical-guide.md).

**Clarification:** Product “Map” / “Backpack” are **device UI features**, not plot locations. A beat named “beach map” or file `beach_map.mp3` is plot audio, not Map.

**Hard rule:** No invented host APIs. Signatures below are quoted from runtime Lua or Flam.RE `dump/flam_api.txt`.

---

## 1. Feature matrix

| Feature | Status | API / pattern (real symbols only) | Evidence |
|---------|--------|-----------------------------------|----------|
| **Backpack (session)** | **Known** (device-proven on Lost Button) | No host `backpack.*`. In-memory table on `Global.*` + UI via `list-choice_1_0_0`.create. See §2 recipe A. | [`stories/lost-button/`](../stories/lost-button/) (`Global.LB`); owner play-test OK; Kipodi bike session bag `Global.KB.backpack` / `KB.have` |
| **Inventory (catalog-style)** | **Partial** (API reconstructed; **not** homebrew device-proven) | Host table `state.inventory`. UI modules `collection`.create / `detail`.create. Items carry `saved` (e.g. `locked`, `hidden`), `title`, `img`, `img_hovered`, `img_locked*`, `audio*`, `detailImg`, `data[]`, `order`, `group`. `Global.sortCollectionTable(inTable)`. Chapter jump may merge `entry.inventory[k].saved` into `state.inventory`. | Runtime `collection.lua`, `detail.lua`, `chapterView.lua`; Flam.RE `plain_scripts/main.DnD.lua` (`display_inventory` → `sortCollectionTable(state.inventory)` → `collection`); `flam-native-lsf.md`; `lua-api.md` §11 (**writing `state` caused relaunch black screens** on games) |
| **Map (chapter map UI)** | **Known** (device-proven via Chapter Map Canary; **no black screen**) | No host symbol named `map`. Map ≈ `Global.progression` (`progressionManager`) + `chapterView` + host `progression.load/save("chaps")`. See §2 recipe B. Canary Chapter Map Canary — owner play-test 2026-11-01 OK (no black screen). | Runtime `progressionManager.lua`, `chapterView.lua`, `global.lua` (`loadBranch`); Flam.RE `flam_api.txt` (`progression.load` / `save` only); owner canary play-test |
| **Choices (list)** | **Known** | `Global.load_module("list-choice","1_0_0").create({ title?, choices[{label,img,audio,cb,show?,slider?}], forcePlay?, title_audio?, exitCb?, skipIfLastChoice? })`. Default `forcePlay = true`. `clean()` → `Global.requestAudioStop()` (no clear). | Runtime `list-choice_1_0_0.lua`; Lost Button |
| **Progression / chaps** | **Partial** | **Host:** `progression.load(name)→table`, `progression.save(name, table)` → `/usr/0/<UUID>/<name>.save` (`flam_api.txt`). **Lua module** (not host): `Global.progression = require("progressionManager")` with `create` / `setProgression` / `displayChapters` / `getProgressionValue` / `isStoryStarted` / `resetProgress`. Host leaf `progress` is assigned from `getProgressionValue()` (library %). | Runtime + `flam_api.txt`; `usr/0/<uuid>.save`, `.prog`, `chaps.save` layout in `flam-native-lsf.md` |
| **Context / lateral menu** | **Partial** | Host `context_menu.set_entries(entries)` where entries are `{ title = string, cb = function }` (sim + fragments). Catalog DnD fragment wires chapters / fiche / inventory callbacks. | `Flam.RE/dump/flam_api.txt`; telmi2flam `engine/main.lua`; truncated `main.DnD.lua` (`…menu.set_entries`); **no original homebrew pack device-proven here** |
| **Save / relaunch** | **Partial** | Prefer **no** `state` writes for short stories (session tables on `Global.*`). Host persists `state` → `.save` / `.prog`. Library bar often stuck ~**1%** on homebrew — do not block ship. | `lua-api.md` §11; `grok-bot-army.md`; Lost Button (no `state` writes) |
| **Title chrome** | **Known** | `title-card`, `title-screen` | Lost Button ending |
| **Audio host** | **Known** | `Global.requestAudioPlay` / `requestAudioStop` + `audio.*` | `global.lua`; Kipodi FL-36/37 diags |

**Status legend**

- **Known** — symbol/pattern recovered from runtime Lua **and** exercised in a personal mint on this fw 2.4.2 unit (or equivalently proven path).  
- **Partial** — real symbols from runtime / Flam.RE, incomplete device proof or known hazards.  
- **Unknown** — no recoverable host/module surface (none remaining in this matrix after this pass).

---

## 2. Minimal homebrew recipes

### A. Session backpack — **proven** (copy Lost Button)

Do **not** call a host backpack API. Do **not** write `state` for short stories.

```lua
-- Orchestrator module (after Global = require("global") in setup)
local LB = {}
Global.LB = LB

function LB.reset()
    LB.has_button = false
end

function LB.show_backpack()
    Global.setBackBehavior(function()
        -- return to prior beat
    end)
    local choices = {}
    if LB.has_button then
        choices[1] = {
            label = "Shiny button",
            img = "button.lif",      -- required string
            audio = "tone.mp3",      -- required string (silent.mp3 OK)
            cb = function()
                -- open keep/leave or item detail beat
            end,
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

-- On pickup beat:
--   Global.LB.has_button = true
--   Global.LB.show_backpack()
```

**Evidence path:** [`stories/lost-button/`](../stories/lost-button/) (`LB.show_backpack`, `lb_find_1_0_0.lua`).

**Kipodi variant (session only, different UI):** `Global.KB.backpack` / `KB.have` — still no host backpack; see [`stories/kipodi-learns-to-ride-a-bike/`](../stories/kipodi-learns-to-ride-a-bike/).

### B. Chapter map — **proven** (Chapter Map Canary, 2026-11-01)

There is **no** `Map.create`. Real stack (device-proven):

1. Init manager (Lua module, via `Global.progression`):

```lua
Global.progression.create({
    totalChapters = 3,                 -- integer; used by getProgressionValue
    backBehavior = function() end,     -- back from chapter list
    chapterViewLabel = "Chapters",     -- optional; default UI string is French
})
```

2. Mark a chapter checkpoint (writes host `progression.save("chaps", …)` and mutates `state`):

```lua
Global.progression.setProgression({
    currentFunction = "ChapterOne",    -- string key into state.visited_funs
    -- branch = "branch-a",            -- optional; else Global.current_branch_name
    ischapter = true,
    chapterData = {
        label = "Chapter one",
        cb = "ChapterOne",             -- string: _G[cb]() or branch[cb]()
        img = "chap1.lif",
        audio = "chap1.mp3",
        order = 1,                     -- optional sort key in chapterView
        -- inventory = { … }           -- optional; copies each v.saved into chap snapshot
    },
})
```

3. Show the chapter list (product “Map”):

```lua
Global.progression.displayChapters(true)  -- forceAudio optional → chapterView.forcePlay
-- equivalent:
-- Global.load_module("chapterView", "").create(backCb, titleLabel, forcePlay)
```

**On chapter row press** (`chapterView.addEntry`): opens `dialog_1_0_0` with hardcoded French confirm (`"Reprendre l'histoire à partir de ce chapitre ?"`), then may merge `entry.inventory` into `state.inventory`, clears `state.visited_funs` / `state.registeredChoices`, and calls `_G[entry.cb]()` or `Global.loadBranch(entry.branch)` + `Global.current_branch[entry.cb]()` when `Global.isMultiBranches`.

**Host progression only** (from `flam_api.txt` — do not invent extra methods):

```text
progression.load(name) → table
progression.save(name, table_data)   -- /usr/0/<UUID>/<name>.save
```

**Homebrew caveats (still real, status is Known for the canary path):**

- Touches `state.*` and disk `chaps.save` — canary relaunch had **no black screen**; still prefer minimal `state` writes outside chapter progression.  
- Confirm dialog strings are French in shipped runtime.  
- Multi-branch needs real branch modules + `Global.loadBranch` (canary was single-branch).  
- Catalog-style `state.inventory` via chapter jump merge remains **Partial** / unproven as a durable inventory path — pre-seed keys if you pass `chapterData.inventory`.  
- Label claims in beat graphs: “uses `chapterView` + `Global.progression` (Known via canary)”, never a fake `Map.*` API.

### C. Catalog inventory + lateral menu — **speculative for homebrew**

Recovered wiring (Flam.RE DnD fragment + runtime), **not** homebrew-proven:

```lua
-- Host (flam_api.txt):
context_menu.set_entries({
    { title = "Chapters", cb = function() Global.progression.displayChapters() end },
    { title = "Backpack", cb = function()
        local ordered = Global.sortCollectionTable(state.inventory)
        Global.load_module("collection", "").create({
            title = "Backpack",
            items = ordered,           -- each item needs .saved, .title, .img, …
            back_cb = function() end,  -- required by collection.create
            -- audio?, empty_text?, group?, hideUse?, override?
        })
    end },
})
```

`collection.create` → click → `detail.create({ item, backModule, hideUse, … })`. Item `saved.locked` / `saved.hidden` gate display/use.

**Do not ship this path** until a tiny original pack survives exit → relaunch ×2. Prefer recipe A for backpack UX.

---

## 3. Quoted signatures (runtime / host)

### Host (`Flam.RE/dump/flam_api.txt`)

| Symbol | Signature |
|--------|-----------|
| `context_menu.set_entries` | `set_entries` (table of entries; homebrew/sim use `{title, cb}`) |
| `progression.load` | `load(name) → table_data` |
| `progression.save` | `save(name, table_data)` → `/usr/0/UUID/name.save` |
| `state` | host table (persisted) |
| `progress` | host leaf (runtime assigns numeric %) |
| `goto_library` | leave story |

No host exports named `map`, `backpack`, `inventory`, or `chapterView`.

### `progressionManager` → `Global.progression`

From `progressionManager.lua`:

```text
create({ totalChapters: integer, backBehavior: function, chapterViewLabel?: string })
setProgression({
  currentFunction: function|string,
  branch?: string,
  ischapter?: boolean,
  chapterData?: {
    label: string, cb: function|string, img: string,
    inventory: table, audio: string, order?: number
  }
})
displayChapters(forceAudio?)
isStoryStarted() → boolean
getProgressionValue() → number   -- #chaps / totalChapters * 100
resetProgress()
restoreBackBehavior()
```

### `chapterView`

```text
create(go_back_cb, titleLabel?, forcePlay?)
addEntry(entry{cb,img,inventory,label,audio,branch?}, parentContainer, FOL?)
recreate() / clean()
```

### `collection` / `detail`

```text
collection.create({
  title, audio?, items[], back_cb, empty_text?, group?, hideUse?, override?
})
collection.showDetail(args) → detail.create
detail.create({ item, hideUse?, overrideAudio?, overrideCallback?, backModule? … })
```

### `Global` helpers used by the above

```text
Global.load_module(name, version)
Global.loadBranch(name)
Global.load_image(path)
Global.setBackBehavior(fn, args?)
Global.setBackModule({name, version, args})
Global.setBackToLibrary()
Global.sortCollectionTable(inTable)   -- order field 1..n
Global.table_length(t)
Global.requestAudioPlay / requestAudioStop
```

---

## 4. Open questions / next RE experiments (USB play-test sized)

Safe, packaging-only experiments — original/dummy assets only:

1. **Chapter canary (1–2 chapters)** — **device-proven (owner play-test)**  
   Host sources: `chapter-map-canary (local canary pack; pattern documented here)`  
      Wiring: `progression.create{totalChapters=2}` → `setProgression{ischapter=true,…}` on enter → hub/chapter **Open Map** → `displayChapters(true)` / `chapterView` → French confirm → `_G.ChapterOne` / `ChapterTwo`. Pre-seeds `state.inventory.canary_token.saved` (chapter jump merge). Dummy LIFF + short tone MP3s only.  
   **Play-test result (owner, 2026-11-01):** **no black screen**. Map status → **Known**. Inventory / catalog-style path still Partial.

2. **`progress` vs 1% quirk**  
   After (1), note on-device library percentage vs `getProgressionValue()` expectation. Do not block ship on 1%.

3. **`context_menu.set_entries` smoke**  
   One entry `{ title = "Ping", cb = … }` that opens `list-choice`. Confirm long-press / M-key lateral menu on device without corrupting back stack.

4. **Session backpack regression**  
   Re-run Lost Button path after any runtime module updates; keep as golden “Backpack = list-choice” reference.

5. **Defer catalog `state.inventory`**  
   (1) is green; after (3) green: one locked/unlocked item through `collection`/`detail` with **minimal** `state.inventory` init, then relaunch ×2. If black screen → purge progress in Flam settings; document failure; keep session backpack as default.

6. **French dialog strings**  
   Decide whether homebrew ships with shipped `chapterView` French confirm or forks a story-local copy (fork = maintenance cost; do not invent a host i18n API).

---

## 5. Recommended homebrew patterns (bots / Flam builder)

| Need | Pattern | Claim in beat graph |
|------|---------|---------------------|
| Choices | `list-choice_1_0_0` | Known |
| Backpack UI | Session table + `list-choice` titled `"Backpack"` | Known (Lost Button) — **prefer this** |
| Map / chapters | `chapterView` + `Global.progression` (canary path) | Known (Chapter Map Canary) — **prefer this** when Map is needed |
| Durable inventory | Avoid `state.inventory` until play-test | Partial / unsafe default |
| Lateral menu | Optional later via `context_menu.set_entries` | Partial |
| Saves | Prefer no `state` writes; session on `Global.*` | Known-safe default |

Wire Story-room beat types `inventory` / `map` **only** to the patterns above. Never emit fake `Map.create` / `backpack.add` host calls.

---

## 6. Source index

| Path | Role |
|------|------|
| [flam-player](https://github.com/scarlaty/flam-player) runtime `script/chapterView.lua` | Chapter map UI |
| flam-player runtime `progressionManager.lua` | Chapter progression Lua API |
| flam-player runtime `collection.lua` / `detail.lua` | Catalog inventory grid / detail |
| flam-player runtime `global.lua` | `loadBranch`, audio, sortCollectionTable |
| flam-player runtime `list-choice_1_0_0.lua` | Choice + session backpack UI |
| [`stories/lost-button/`](../stories/lost-button/) | Proven session backpack |
| Chapter Map Canary (local experiment) | Chapter-map path — **device-proven, no black screen** (owner 2026-11-01) |
| [`stories/kipodi-learns-to-ride-a-bike/`](../stories/kipodi-learns-to-ride-a-bike/) | Full story: backpack + chapters + mini-game |
| [Flam.RE](https://github.com/o-daneel/Flam.RE) `dump/flam_api.txt` | Host `progression` / `context_menu` |
| Flam.RE `plain_scripts/main.DnD.lua` | Truncated catalog lateral + inventory wiring (do not ship catalog content) |
| [flam-homebrew lua-api](https://github.com/scarlaty/flam-player/tree/main/skills/flam-homebrew) | Whitelist + `state` relaunch hazard |
| [`flam-native-lsf.md`](flam-native-lsf.md), [`authoring-full-story.md`](authoring-full-story.md), [`flam-fw2-technical-guide.md`](flam-fw2-technical-guide.md) | Pack shape / authoring / fw2 digest |

---

*Packaging/interop only. Dummy or original assets in examples. No CFW. No official catalog content retained in this doc.*
