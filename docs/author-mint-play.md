# Author → mint → play (fw 2.4.2)

Repeatable workflow for personal Flam-native packs on this laptop. No CFW. No official-content rip.

## Mint model (one-liner)

Firmware derives story AES by **encrypting** the on-disk `key` under the device key; set `key = SNU32` (`SNU24||SNU24[0:8]`) so `story_key/iv = .mdf C0/C1`, then AES-128-CBC (zero-pad) `info` + `*.lsf` with C0/C1 and leave media plain — device key never needed. Full write-up: [`fw2-key-wrap.md`](fw2-key-wrap.md).

## Paths on this laptop

| Role | Path |
|---|---|
| Flam USB mount (when attached) | `/run/media/yariminal/FLAM` |
| Block device (typical) | `/dev/sda` / `/dev/sda1` (confirm with `lsblk`) |
| SNU / USB id | `30224020004727` · VID:PID `303a:819e` |
| flam-homebrew skill | `/home/yariminal/flam-re/flam-player/skills/flam-homebrew/` |
| Build / check | `…/scripts/flam_build.py`, `flam_check.py`, `new_project.py` |
| Mint tooling | `/home/yariminal/flam-re/flamtool/` (`pack.py`, `mint.py`, `cleanup.py`, …) |
| Python (pycryptodome) | `/home/yariminal/flam-re/luniiqt-tools/venv/bin/python` |
| Example proven pack | scarlaty `casse-briques.plain.pk` (device-OK on 2.4.2) |

Export helpers (optional):

```bash
export FLAM_ROOT=/run/media/yariminal/FLAM
export HB=/home/yariminal/flam-re/flam-player/skills/flam-homebrew
export FT=/home/yariminal/flam-re/flamtool
export PY=/home/yariminal/flam-re/luniiqt-tools/venv/bin/python
```

## Workflow

### 1. Author / build (host)

```bash
# new project once
python3 "$HB/scripts/new_project.py" ~/flam-stories/my-story

# edit main.lua + script/*.lua + img/ + sounds/ under the project
# then assemble .plain.pk (runs flam_check unless --no-check)
python3 "$HB/scripts/flam_build.py" ~/flam-stories/my-story -o ~/flam-stories/my-story.plain.pk
```

Require **zero `[ERR]`** from `flam_check`. Prefer simulator `--strict` before device when available.

### 2. Mount Flam

```bash
# if not auto-mounted:
udisksctl mount -b /dev/sda1
# confirm:
test -f "$FLAM_ROOT/.mdf" && echo ok
```

### 3. Pack (or mint)

**Preferred for full homebrew:** `pack.py` reads `.plain.pk`, ciphers Lua→`.lsf` + `info.plain`→`info`, writes SNU32 `key`, appends UUID to `etc/library/list`, deletes `usr/0/library.cache`.

```bash
$PY "$FT/pack.py" "$FLAM_ROOT" ~/flam-stories/my-story.plain.pk
```

**Bare hello / single Lua:** `mint.py` (no ZIP). Still must be a `Global.load_module` story for real play — see pitfalls.

```bash
$PY "$FT/mint.py" "$FLAM_ROOT" <uuid> "Title" /path/to/main.lua \
  --more /path/to/script/foo_1_0_0.lua=script/foo_1_0_0.lsf   # only if already ciphered… prefer pack.py
```

For authored modules, always use **`pack.py` + `.plain.pk`** so plaintext Lua is ciphered correctly.

If UUID already exists under `str/`, remove it first (`cleanup.py` or manual) — pack refuses overwrite.

### 4. Sync and clean eject

USB is slow and flaky; never yank power mid-write.

```bash
sync
udisksctl unmount -b /dev/sda1
udisksctl power-off -b /dev/sda
```

### 5. Power-cycle and verify

1. Power Flam into the library menu (not still in mass-storage).
2. Title should be readable (not garbage) — device rebuilds `library.cache` from decrypted `info`.
3. Open story: UI + wheel work; exit to library and **relaunch twice without reboot** (relaunch bugs are real — see § pitfalls).
4. Optional host readback after remount: `$PY "$FT/readback.py" "$FLAM_ROOT"`.

### 6. Cleanup test packs

```bash
$PY "$FT/cleanup.py" "$FLAM_ROOT" [--prefix ba770000-]
sync && udisksctl unmount -b /dev/sda1 && udisksctl power-off -b /dev/sda
```

## Pitfalls (from [`fw2-key-wrap.md`](fw2-key-wrap.md) §10 + device contract)

| Trap | Symptom | Fix |
|---|---|---|
| Bare `main()` / UI outside `Global.load_module` | Instant return to menu / black screen / dead inputs | Game = module: `Global.load_module("name","1_0_0").create({})`; `clean()` tears down |
| `Global = require("global")` as `local` | Broken Global | Assign **global** `Global` inside `setup()` |
| Top-level `require` in `main.lua` | Fail to load | Only `require` inside `setup()` (or later) |
| Missing runtime (`global`, buttons, …) | `module 'global' not found` | Let `flam_build.py` embed `assets/runtime` |
| Wrong key wrap (v3-trick / C0C1 as keyfile) | Garbled title, stuck load | Use mint: keyfile=SNU32, cipher with C0/C1 |
| UUID already on device | Pack exit / “already loaded” | Delete old `str/<uuid>` + list line first |
| Skip `sync` / dirty unmount | Corrupt or missing story | Always `sync` + `udisksctl unmount` + `power-off` |
| Latin-1-only fonts | Empty boxes | ASCII / Latin-1 strings; `font_safe` for titles |
| `io` / `os` / `debug` | Lua error | Sandbox whitelist: `lv.*`, `Global.*`, `audio.*` |
| `audio.load` while playing | Hard freeze | Load only when `audio.get_status() == "stop"` |
| Write into `state` / clean on library exit | Black screen on **2nd** launch | See flam-homebrew `device-pitfalls.md` Relance; test exit→relaunch without reboot |
| Screen size | Clipped UI | 320×240; play area 320×212 under title bar |

## Proven on this unit (owner steps 1–4)

1. Flam mount path exercised  
2. `casse-briques` packed and played  
3. Original hello minted  
4. Battery experiment cleaned  

Next content work: richer interactive stories via [`ai-flam-pipeline.md`](ai-flam-pipeline.md).
