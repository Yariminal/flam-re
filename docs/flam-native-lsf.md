# Flam-native LSF — packaging & runtime

Research note (2026-10-26). Sources: public [Flam.RE](https://github.com/o-daneel/Flam.RE) (ANALYSIS, CIPHERING, LIFF_SPEC, `dump/`, `tools/python/`), [Lunii.QT](https://github.com/o-daneel/Lunii.QT) Flam paths + [issue #75](https://github.com/o-daneel/Lunii.QT/issues/75), on-device verify of UUID `c103c95c-a852-4d8f-9c03-82f3814b572d` (layout / magic / entropy only). **No Emily prose, audio, or images copied into the store.**

## On-device tree (verified)

```
str/<UUID-v4>/
  version          # 1 byte plain — Emily: ASCII '3' (0x33)
  info             # 128 B opaque — story-key ciphered metadata
  key              # 32 B opaque — device-key wrapped story AES key+IV
  main.lsf         # entry script — story-key ciphered Lua
  script/*.lsf     # modules — same cipher model
  img/*.lif        # plain LIFF (`liff` magic)
  img/script/*.lif # UI chrome LIFF (arrows, play/pause, lock, …)
  sounds/*.mp3     # plain MPEG/ID3
  sounds/*.mp3map  # plain timing sidecars (12–N bytes)
```

Library: `etc/library/list` (ASCII UUID lines). Progress: `usr/0/<UUID>.save`, `.prog`, `<UUID>/chaps.save` (Lua-table serialization; see Flam.RE `dump/lua_save.bt`).

Emily counts on this unit: **35** `script/*.lsf`, **186** LIFF under `img/`, **202** MP3 + **202** mp3map. No classic `ni`/`li`/`ri`/`si`.

### Plain vs ciphered (this device)

| File | Magic / entropy | Verdict |
|---|---|---|
| `version` | printable `3` | plain |
| `img/*.lif` | `liff` | plain (LIFF / QOI-derived; [LIFF_SPEC](https://github.com/o-daneel/Flam.RE/blob/main/LIFF_SPEC.md)) |
| `sounds/*.mp3` | `ID3` / MPEG | plain |
| `sounds/*.mp3map` | structured LE fields | plain |
| `info` | ~6.6 bits/byte, 128 B | ciphered |
| `key` | 32 B high entropy | wrapped blob (≠ Lunii.QT forged keyfile) |
| `main.lsf` / `script/*.lsf` | ~8.0 bits/byte | ciphered |

`main.lsf` first 16 B on Emily: `b7231ebe…` — **not** the Flam.RE sample header `89837de8…` (header is per-ciphertext / per-key, not a fixed magic).

## Key / info model

From Flam.RE CIPHERING + ANALYSIS + Lunii.QT `device_flam.py` + community [#75](https://github.com/o-daneel/Lunii.QT/issues/75):

| Material | Role |
|---|---|
| **Device key + IV** (AES-128) | Wraps on-disk `key`; also second half of `.mdf` (SNU×2 ciphertext). Device-bound; **not** recoverable from fw-2.x `.mdf` host parse alone. |
| **Story key + IV** (AES-128) | Decrypts `info` + `*.lsf`. Flam.RE notes a story key can be shared across titles; on-disk `key` can be identical across stories on one device. |
| **On-disk `key` (32 B)** | `story_key[16] \|\| story_iv[16]` encrypted under device key. Firmware unwraps this; forged Lunii.QT `keyfile` does **not** substitute. |
| **Lunii.QT forged `keyfile` (fw 2.x)** | `hexlify(SNU) \|\| 10×0x00 \|\| hexlify(SNU)[:8]` — used for **classic** imports. Emily’s native `key` **≠** this forge on our unit. |

Host probe (2026-10-26): AES-CBC of Emily `info` / `main.lsf` with `.mdf[0x4E:]` story_key/iv, forged halves, on-disk key halves, and `reverse_bytes` variants → **no** Lua keywords / printable Lua. **Device key from `.mdf` does not unwrap native scripts** with materials Lunii.QT exposes for classic AES.

[#75](https://github.com/o-daneel/Lunii.QT/issues/75) (fw 1.x A/B): replacing official wrapped `key` with Lunii.QT `keyfile` + re-ciphering LSF under SNU-derived story key → garbage title + load fail; restoring original wrapped `key` + ciphertext restores play. Same auth model is the working hypothesis for fw **2.4.2**.

Flam.RE `tools/python/crypto_tool.py` shows the authoring shape (keys **redacted** in public tree): write wrapped `key`, AES-CBC zero-pad `info` and Lua→`.lsf`. Custom test packs were marked OK there — implying the RE author held a real device wrap, not published.

### `info` shape (public tooling hints)

- Official: ciphered; library title comes from decrypt + `usr/0/library.cache`.
- Flam.RE `crypto_tool.py` builds plaintext as `title + "\nscript/local.lsf"` then AES-CBC — suggests title line(s) plus optional script path, not the 5-line classic Lunii.QT `__write_info` text.
- Classic imports use **plain** multiline `info` ([`custom-pack-sidecars.md`](custom-pack-sidecars.md)) — different path.

## Script packaging (LSF)

- Extension `.lsf` = ciphered Lua source (Lua **5.4** per `dump/flam_version.txt`). Runtime loads `main.lsf`, then `require` / `Global.load_module` pulls `script/<name>.lsf`.
- Shared UI modules recur across catalog titles (byte-identical hashes in `dump/flam_lsf.txt`): e.g. `minimal`, `v-container`, `h-container`, `button*`, `dialog*`, `list-choice*`, `image-choice*`, `collection`, `progressionManager`, `title-card`, `audio-player_*`, …
- Story-specific: `main.lsf`, branch scripts, plus Emily-only names observed on disk (`composer`, `thread`, `list-quiz`, `image-panoramic`, `note`, …) — names only; no content dump.
- Images/audio referenced by basename (`.lif` / `.mp3`); screen **320×240** (`global` fragments).

### Control-flow patterns (identifiers only)

From Flam.RE partial `plain_scripts/` (many chunks marked `[ _AES_LOST_ ]`) + API dump:

1. `setup` / `init` → `require("global")` → `progression.create({…})` → `Global.loadBranch(...)` or `Global.load_module(name, …)`.
2. Choice UIs via modules `list-choice_*`, `image-choice_*`, `dialog*`; callbacks into story functions.
3. Lateral menu via `context_menu.set_entries` / menu entries pointing at inventory / chapters / character sheet.
4. Inventory lives in `state.inventory`; chapters via `progression.load("chaps")` / `progression.save`.
5. Audio via host `audio.*` and/or `audio-player_*` module + pause chrome under `img/script/`.

## LIFF & audio (authorable today)

- **LIFF:** fully specified; [o-daneel/lif](https://github.com/o-daneel/lif) + Lunii.QT `image_to_liff`. Not encrypted.
- **MP3:** plain; Flam.RE examples ~128 kb/s stereo 44.1 kHz.
- **mp3map:** sidecar; short maps 12 or 20 B; longer maps = header + repeating LE records (seek/segment table — exact schema TBD). Dummy short map sufficient for hello audio once scripts run.

## API surface (if recovered)

**Filter method:** (1) public `Flam.RE/dump/flam_api.txt` host globals; (2) `require` / call sites surviving in public `plain_scripts/*.lua`; (3) on-device **filename** inventory only; (4) save-file identifier regex `[A-Za-z_][A-Za-z0-9_]{2,40}` kept only if matching API/state domains (`inventory`, `item_*` pattern, `audio`, `chapter`/`chaps`, `registeredChoices`, `locked`, `saved`, `fullscreenImage`, …) — **story-specific token values discarded**.

### Host globals / modules

| Name | Notes |
|---|---|
| `audio` | `load`, `play`, `pause`, `pause_resume`, `stop`, `seek`, `tell`, `duration`, `get_status`, `get_volume`, `set_volume` |
| `progression` | `load(name)→table`, `save(name, table)`; also `create({…})` in scripts |
| `progress` | present (leaf in dump) |
| `screen` | `set_state`, `on_state_changed`, `EVENT_POWERON`, `EVENT_POWEROFF` |
| `context_menu` | `set_entries` |
| `goto_library` | leave story → library |
| `document`, `window`, `state`, `current_time` | host objects / tables |
| `lv` | LVGL Lua bindings (widgets, styles, events, align, …) |
| `package` | standard + writable `cpath` (Flam.RE validated) |
| `require` / `dofile` / `loadfile` | module load from ciphered `script/` |
| Lua 5.4 stdlib | `string`, `table`, `math`, `utf8`, coroutines, … |

### Story-framework identifiers (from public plain fragments)

`Global`, `Global.load_module`, `Global.loadBranch`, `Global.load_image`, `Global.sortCollectionTable`, `Global.setBackBehavior`, `Global.table_length`, `progressionManager`, `progression.create`, `progression.load`, `progression.save`, `state.inventory`, `state.current_fun`, `state.visited_funs`, `registeredChoices`.

### Script module basenames (shared UI toolkit)

`minimal`, `global`, `button`, `button-theme`, `button-theme-default`, `button-theme-interactive`, `v-container`, `h-container`, `v-scroll`, `dialog`, `dialog_1_0_0`, `list-choice_1_0_0`, `list-choice-circular`, `image-choice_1_0_0`, `image-Button`, `image-stress`, `full-screen-image`, `collection`, `detail`, `title-card`, `title-screen`, `audio-player_1_0_0`, `modal-info_0_9_0`, `notification`, `progressionManager`, `chapterView`, `dice-roll`, `composer`, `thread`, `list-quiz`, `image-panoramic`, `note`, `dialog-interactive`, `horizontal-notification` (last group seen on Emily filenames only).

### Not recovered as a public callable list

Dedicated host names for backpack / map / traits / rewards beyond `state.inventory` + `collection` / chapter UI modules. Those features appear implemented **in Lua modules**, not as separate C host exports in `flam_api.txt`.

## Authoring status

| Piece | Status |
|---|---|
| Tree layout | Known + verified |
| LIFF / MP3 | Authorable |
| Lua API sketch | Partial (above) |
| Cipher `info`/`*.lsf` once story key known | AES-CBC, zero-pad (Flam.RE tool) |
| Mint firmware-accepted `key` for **new** UUID | **Blocked** on fw **2.4.2**. Flam.RE **v3 trick** **failed** (garbled title + load stuck at 1%). Lunii.QT fw-2 forge same class ([#75](https://github.com/o-daneel/Lunii.QT/issues/75)). No host-side wrap known. |
| Public complete LSF schema / clean framework sources | Missing (`plain_scripts` heavily `[ _AES_LOST_ ]`) |

### Key experiment (2026-10-26) — closed fail

- Deployed v3 trick UUID `dc0bf8f5-…` → owner: title `o:xZ'_2aKaMD(`, load **1%**; Emily OK. Canary **purged**. Personal native packs still blocked. Remaining ranks: Flam.RE author contact → official studio/FAH/Mon Studio → deeper non-SWD key lead if any → accept wall → SWD only if owner asks. Docs: [`flam-key-options.md`](flam-key-options.md), [`flam-key-experiment-results.md`](flam-key-experiment-results.md); staging kept on host: `internal/flam-native-hello/`.

Skeleton steps + blockers: [`internal/flam-native-skeleton-plan.md`](../internal/flam-native-skeleton-plan.md). Path ranking: [`flam-native-path.md`](flam-native-path.md).
