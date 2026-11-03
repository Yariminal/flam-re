# Lunii Flam fw 2.x — technical digest

**Basis:** Flam.RE technical notes + host authoring on stock fw **2.4.2** (`2.4.2-bc9881da`).  
**Scope:** packaging / interop / authoring only. No CFW, no flash/UART exploit paths as actionable work, no catalog prose/audio retention.

Confirmed on stock firmware via the host authoring channel (§5). No hardware opened, no firmware modified in the source sessions.

Also see: [`fw2-key-wrap.md`](fw2-key-wrap.md) (mint model), [`map-backpack-re.md`](map-backpack-re.md), [`authoring-full-story.md`](authoring-full-story.md), [`project-context.md`](project-context.md).

---

## 1. Hardware

- Main MCU: ESP32-S3 (native USB, story engine, LVGL, Lua)
- Comm MCU: ESP32-MINI-1 (WiFi/BT)
- Storage: µSD 8 GB on SDIO, FAT (Torx 6; card host-accessible without USB)
- USB: VID:PID `303a:819e` ("Lunii FLAM"), mass-storage
- Screen 320×240 (play area 320×212), wheel (rotation + click), back button

## 2. USB behavior

- Enumeration can be flaky (`error -71`); power on first, data cable, retry
- Throughput low (~4 min / 80 MB) — keep writes small
- Always `sync` + clean unmount before power-off; dirty ejects → `FSCK*.REC` at volume root
- Stories / `usr/0/library.cache` rescanned only at boot

## 3. Filesystem map (observed)

```
/.mdf                        126 B identity + ciphered region (§4)
/etc/library/list            visible story UUIDs (lowercase, one per line)
/etc/library/list.hidden     hidden stories
/etc/wifi/networks/N         PLAINTEXT: "SSID\nPSK" (host-editable)
/etc/bluetooth/config/active plaintext "true"/"false"
/etc/update/need_sync        plaintext "false"
/etc/stats/ke                binary, device-global counters, ciphered tail
/etc/stats/<uuid>            binary, per-story stats
/usr/0/library.cache         decrypted title cache, rebuilt at boot (§6.2)
/usr/0/<uuid>.save           default save blob
/usr/0/<uuid>.prog           4 B progress record
/usr/0/<uuid>/<name>.save    named saves (e.g. progression.save / chaps)
/str/<uuid>/                 story dir (§5.3)
/str.hidden/<uuid>/          hidden stories
/tmp/cable_update_complete   OTA trigger flag
/update-main.enc             OTA main image (root, §7)
/update-comm.enc             OTA comm image
```

## 4. .mdf byte map (126 B)

```
0x00  01 00                          static
0x02  "2.4.2-bc9881da" + NULs        fw version, 48 B field
0x32  "30224020004727" + NULs        SNU ascii, 24 B field (SNU24)
0x4A  3a 30 9e 81                    VID/PID LE: 0x303A / 0x819E
0x4E  C0 C1 C2 (3×16 B)              Enc_devkey(SNU24 || SNU24)
```

Known-pair oracle (device key never needed for authoring):

```
B0 = "30224020004727\0\0"      Enc_devkey(B0) = C0 = .mdf[0x4E:0x5E]
B1 = "\0"*8 + "30224020"       Enc_devkey(B1) = C1 = .mdf[0x5E:0x6E]
B2 = "004727" + "\0"*10        Enc_devkey(B2) = C2 = .mdf[0x6E:0x7E]
```

## 5. The key wrap (SOLVED, confirmed 2.4.2)

### 5.1 Model

Firmware does **not** decrypt `str/<uuid>/key`. It **encrypts** it:

```
story_key = Enc_devkey(key[0:16])     AES-128-ECB, block-independent
story_iv  = Enc_devkey(key[16:32])
```

Content (`info`, `main.lsf`, `script/*.lsf`) = AES-128-CBC under story_key/story_iv, zero padding (no extra block when aligned).  
Media (`img/*.lif`, `sounds/*.mp3|.mp3map`, `version`) = plaintext.

### 5.2 The mint (host-side, any new UUID)

```
key file = (SNU24||SNU24)[0:32] = B0||B1
         = hexlify(snu) + "\0"*10 + hexlify(snu)[:8]
cipher everything with key = C0 = .mdf[0x4E:0x5E], iv = C1 = .mdf[0x5E:0x6E]
```

Only C0/C1 reachable this way (three known pairs total) — enough for all authoring. Device key stays on-chip.

### 5.3 Story directory

```
str/<uuid>/key        32 B, as above
str/<uuid>/info       ciphered: "title\nsubtitle\n000000\ntitle" zero-padded
str/<uuid>/main.lsf   ciphered Lua entry (firmware calls setup())
str/<uuid>/script/*.lsf   ciphered Lua modules
str/<uuid>/version    plain ("3" official 2.x packs, "1" homebrew)
str/<uuid>/img/...    plain .lif
str/<uuid>/sounds/... plain .mp3 + .mp3map
```

Append UUID to `etc/library/list`, delete `usr/0/library.cache`, boot.

### 5.4 Why previous approaches failed

- **v3-trick** (`key = .mdf[0x4E:0x6E]`, content under SNU-derived key): keyfile passes through `Enc_devkey` again → garbage story key (same class as Lunii.QT #75 on fw 1.x)
- **74k offline KDF** vs official story: 0 hits — device key is factory random, not derived
- **Lunii.QT fw2 branch** (`key = SNU32`, content under raw mdf bytes) **is** the working model; reported fails were fw1 branch or pre-2.x firmware

## 6. File formats

### 6.1 info (plaintext form)

`title\n subtitle \n "000000" \n title` — title repeated on line 4 (outside CBC block 1 → IV-wrong diagnostic). Zero-padded to 16.

### 6.2 library.cache

```
0x00  u32 count?
0x04  fw string, NUL-padded
per story:  u16le len + uuid ascii + NUL
            u16le len + "/str/<uuid>" + NUL
            u16le len + decrypted title (UTF-8) + NUL
            thumbnail block ("liff" marker + RGB565)
```

Firmware decryption lands here in plaintext — host readback channel for battery verdicts.

### 6.3 save files (progression.save)

Tagged key/value blob. Observed: `06 <klen> <key> 15 <len:u16le> <bytes>` per string entry; numeric values raw (volume=75 → `0a 4b 00`). Written to `/usr/0/<uuid>/<name>.save`. Keys may be out of order.

## 7. Firmware update channel (observed packaging facts)

- Endpoint pattern: `GET …/devices/{snu}/firmware?installed=…&chipset=main|comm` (Luniistore account token)
- Example sizes (2026-11-01): `update-main.enc` ≈ 1 708 080 B, `update-comm.enc` ≈ 1 577 008 B
- Fully encrypted (high entropy; no ESP32 `0xE9` magic; not ECB; no shared blocks between files). Decryption key on-device
- Install: drop both at volume root + empty `tmp/cable_update_complete`, eject while connected; device consumes files

**Project note:** documenting the cable-update layout is fine for interop. Patching OTA / flashing CFW is **out of scope** (prefs).

## 8. Lua sandbox (PROBE01/PROBE02, fw 2.4.2)

### 8.1 Execution model

- `main.lsf` loads with default `package.path` (`/lib/lua/?.lua;…` — internal flash has `/lib/lua/`)
- Firmware then rewrites `package.path` to `/str/<uuid>/script/?.lsf;/str/<uuid>/script/?.lua` and calls `setup()`
- Back: firmware calls global `back_callback`. Prefer `Global.setBackToLibrary()` / `Global.setBackBehavior(fn)`; bare stories may need power-cycle to exit
- Errors leak decrypted paths (`/str/<uuid>/main.lsf:NN`) — cipher transparent to interpreter

### 8.2 Present globals (census)

`audio` (duration, get_status, get_volume, load, pause, pause_resume, play, seek, set_volume, stop, tell), `break_gdb`, `context_menu` (set_entries), `coroutine`, `current_time` (ms uptime), `document`, `goto_library`, `lv` (full LVGL: obj, label, img, slider, arc, roller, menu, qrcode, timer, group, style, font nunito_*, symbol glyphs), `math`, `package` (cpath empty; loadlib stubbed), `print`, `print_mem_stat`, `progress` (number), `progression` (load/save), `screen` (set_state, on_state_changed, EVENT_POWERON/OFF), `state` (session table), `string` (incl. dump), `table`, `utf8`, `warn`, `window`, stdlib (`assert`, `error`, `ipairs`, `next`, `pairs`, `pcall`, `xpcall`, `raw*`, `require`, `select`, `setmetatable`, `tonumber`, `tostring`, `type`)

### 8.3 Absent / closed (verified)

- `io`, `os`, `debug`, `load`, `loadfile`, `dofile`: nil
- Bytecode escape dead (`load` absent)
- `package.loadlib` stubbed — no dynamic loader
- `require` cannot leave story dir (`/` mangled to `.`)
- `progression.save("../x")` accepted but writes nowhere visible
- `screen.set_state(EVENT_POWEROFF)` from app: no-op (firmware→app notify only)
- No backlight / BT / WiFi radio API; no FS enumeration
- `goto_library()` is the only exit to story list

### 8.4 Measured values

- `audio.get_volume()` = 50 default, 0–100; `set_volume` live and **system-wide**
- `current_time()` = ms since boot
- `context_menu.set_entries({})` accepted (entry shape untested on unsigned packs)

## 9. Runtime module wiring (catalog framework, reconstructed)

flam-player runtime (`tools/telmi2flam/runtime/script/`) is the catalog framework in plaintext; official packs ship same module names ciphered. **Do not retain catalog prose/audio** — module wiring only.

1. **Host symbols:** nothing beyond `progression.load/save` + `context_menu.set_entries`. **No** map/backpack/inventory host API — all Lua modules
2. **Catalog wiring:** chapters via `progressionManager.setProgression{ischapter=true, chapterData={label,cb,img,audio,order?,inventory?}}` → `progression.save("chaps")`; `displayChapters()` → `load_module("chapterView","").create(...)`. Reconstructed runtime does **not** use `context_menu.set_entries` (lateral chrome = catalog-main)
3. **chaps.save shape:** array of `{label, branch, cb, img, audio, order?, inventory?}`. `cb` must be a **string** (resolved via `_G[cb]()` / `current_branch[cb]()`). Call `progressionManager.create{totalChapters, backBehavior}` at boot before chapter display. **Relaunch black-screen hazard is `state` writes, not the chaps file itself**
4. **context_menu on unsigned packs:** unproven; empty-set OK; framework does not depend on it
5. **chapterView:** French confirm strings hardcoded in runtime copy — fork for other languages. Chapter jump merges `entry.inventory` into `state.inventory[k].saved` and **crashes if the key is absent** — pre-seed every inventory key at boot. `img`/`audio` nil-OK. Ship UI chrome `.lif` under `img/script/`. `getProgressionValue = #chaps/totalChapters*100`

Chapter jump: resets `state.visited_funs` + `state.registeredChoices`, then `Global.loadBranch(entry.branch)` + branch cb (multi-branch) or `_G[entry.cb]()` (single-branch).

## 10. Homebrew contract (device-proven)

- `.plain.pk` = stored ZIP: `uuid.bin` (16 B), `info.plain`, `version`, `main.lua`, `script/<module>_<ver>.lua`, `img/**`, `sounds/**`
- `main.lua`: firmware calls `setup()`; `Global = require("global")` **global**, no `local`; no top-level `require` outside `setup()`
- Content = module: `Global.load_module("name","1_0_0").create({})`, paired `clean()`. Drawing `lv.*` outside current module → black screen
- Wheel: `lv.EVENT_KEY`, `string.byte(lv.event.get_key_value(e))` — 19 right, 20 left. Click: `lv.EVENT_CLICKED`. Container in `document` group + `lv.group.set_editing(document, true)`
- Timers: one-shot logic needs fired-flag (`lv.timer.new` repeats)
- Event callbacks: do **not** `goto_library()` raw inside one — defer ~100 ms timer or use `setBackToLibrary()`. (Hub v1: raw call → watchdog restart)
- Exit without cleaning for instant relaunch; relaunch twice to catch second-launch black screens
- Latin-1 text only; 320×212 play area; **single audio track**; host `audio.load` only when `audio.get_status() == "stop"` (prefer `Global.requestAudioPlay` — see [`authoring-full-story.md`](authoring-full-story.md) for priority / `clean()` races)

## 11. Tooling (`~/flam-re/flamtool/`)

| file | purpose |
|---|---|
| `flam.py` | .mdf parse, C0/C1/B*/SNU32, AES-CBC helpers, story writer |
| `mint.py <root> <uuid> <title> <main.lua>` | single authored story |
| `pack.py <root> <story.plain.pk>` | homebrew pack → device, self-keyed |
| `build_hub.py` | Flam Hub .plain.pk |
| `battery.py` / `readback.py` | hypothesis battery + library.cache verdicts |
| `oracle_info.py` | offline story-key candidate test |
| `cleanup.py` | remove test stories by UUID prefix + reset cache |
| `probe.lua` / `probe2.lua` | on-device sandbox census via progression.save |

Python: `~/flam-re/luniiqt-tools/venv/bin/python` (pycryptodome).

Session: mount → pack/mint → `sync` → clean unmount → power-cycle → test → reconnect → readback.

## 12. Experiment log (source summary)

- Battery V01–V12 + control: only **V04** (key=SNU32, content under raw C0/C1) readable → ECB encryption-of-keyfile confirmed
- PROBE01/02: sandbox census, loadlib stub, require-escape dead, volume=50
- casse-briques: plays, wheel OK, exit/relaunch clean
- Flam Hub v1.1: volume live+persisted; raw `goto_library()` in back cb → restart; `screen.set_state` → no-op

## 13. Open items (scoped)

**In scope / useful for authoring:**

- UUID binding of official keyfiles untested (full media copy never run) — not needed for personal mint
- WiFi sync protocol (`192.168.4.1:3334` TCP) unexplored — host settings today are plain `/etc/wifi/networks/N`, `/etc/bluetooth/config/active`
- Chapter map **Known** on homebrew (Chapter Map Canary UUID `9c2d8f63-…`, owner play-test **no black screen**); catalog inventory still **Partial** ([`map-backpack-re.md`](map-backpack-re.md))

**Out of scope (prefs — listed only so we do not rediscover them as “next steps”):**

- Device-key recovery / official-pack decrypt (needs flash dump or OTA key RE) — optional catalog analysis only; never retain catalog prose/audio in Project docs
- CFW, UART flash readout as a product path, OTA patching

## 14. Conflicts with prior Project notes

Honest deltas vs docs already in this store:

| Topic | Prior Project note | Guide | Verdict |
|-------|-------------------|-------|---------|
| **Key wrap** | [`fw2-key-wrap.md`](fw2-key-wrap.md): SNU32 key + C0/C1 CBC; firmware encrypts keyfile | Same model, same mint | **No conflict** — guide is the fuller consolidated write-up; keep both (this digest = umbrella; fw2-key-wrap = mint-focused) |
| **v3-trick / KDF miss** | Documented fails in project-context / experiment docs | Explained as double-Enc_devkey / non-derived device key | **Corrected understanding** (already reflected in fw2-key-wrap); no factual clash |
| **Map / Backpack** | [`map-backpack-re.md`](map-backpack-re.md): no host map/backpack; session backpack = list-choice (**Known**); chapter map = progressionManager + chapterView (**Known** via canary, no black screen); catalog inventory **Partial** | §9 same conclusions | **Aligned**. Guide adds: black-screen hazard is **`state` writes**, not `chaps.save`; chapter jump **crashes if inventory key missing** — pre-seed at boot |
| **context_menu** | Partial / unproven on homebrew | Empty-set accepted; unsigned packs unproven; framework independent | **Aligned** |
| **Audio** | [`authoring-full-story.md`](authoring-full-story.md): `requestAudioPlay` priority, no stop-all in `clean()`, 500 ms delayer | Firmware: single track; `audio.load` only when status `"stop"`; volume system-wide | **Complementary, not conflicting**. Guide is host/`audio.*` floor; our handoff is runtime `Global.*` layer that Kipodi violated |
| **Hub / exit** | Lost Button / handoff: careful library exit | Raw `goto_library()` in callback → watchdog; defer ~100 ms or `setBackToLibrary` | **Aligned**; reinforce in builder docs |
| **CFW / flash / OTA patch** | Prefs + project-context: no CFW | Source §13 lists UART dump / OTA patch as forward routes | **Preference conflict with source open items** — we keep facts, mark routes out of scope (§13 above) |
| **Catalog content** | Never retain official prose/audio | Source discusses official packs / Emily as oracles | **Process conflict only** — digest keeps packaging/crypto facts; no catalog text/audio copied here |

## 15. Pointers (external)

- Flam.RE tree: `CIPHERING.md`, `FW2_KEY_WRAP.md`, `ANALYSIS.md`, `HARDWARE.md`, this guide’s source path above
- Lunii.QT (o-daneel): import/export + fw download paths
- scarlaty/flam-player: emulator, telmi2flam runtime, flam-homebrew skill
- Classic lineage: o-daneel/Lunii.RE, Lunii_v3.RE

---

*Packaging/interop digest. Original/dummy assets only for authoring. No CFW. No official catalog content retained.*
