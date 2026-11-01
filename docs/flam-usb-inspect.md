# Flam USB inspect (2026-10-26)

Safe layout pass on the owned Flam mass-storage volume. **No** story content export, decryption, or firmware changes. Official pack was filename/size/magic only; stopped after layout classification.

## Mount

| Field | Value |
|---|---|
| Mount | `/run/media/yariminal/FLAM` |
| Device | `/dev/sda1` (parent `/dev/sda` 7.5G USB Mass Storage) |
| FS | `vfat` (`rw`, udisks2) |
| USB ID | `303a:819e` — `Lunii FLAM` |
| Serial | `30224020004727` |
| Firmware (`.mdf` printable) | `2.4.2-bc9881da` |
| Capacity | 7.5G total, **~101M used**, **~7.5G free** (~2%) |
| Writable | **Yes** (create+delete probe of `.write-test-cursor` succeeded) |

Ready for later Lunii.QT import (plenty of free space).

## Top-level layout

```
FLAM/
  .mdf          # 126 B device metadata (fw + serial)
  etc/          # ~224K  config / library index / wifi / stats
  str/          # ~101M  stories (UUID dirs)
  tmp/          # empty
  usr/          # ~128K  per-profile cache / .save / .prog
```

### Non-story config (safe reads)

- `etc/library/list` — **ASCII text**, one UUID per line:
  - `c103c95c-a852-4d8f-9c03-82f3814b572d`
- `etc/update/need_sync`, `etc/bluetooth/…`, `etc/wifi/…`, `etc/stats/…` present (not opened beyond listing).
- `usr/0/` has `library.cache` plus `.save` / `.prog` sidecars for the same UUID.

## Stories under `str/`

**Count: 1** UUID directory.

| UUID | Size | Notes |
|---|---|---|
| `c103c95c-a852-4d8f-9c03-82f3814b572d` | **101M** | Only pack on device |

### Custom / third-party?

**No custom candidate.** UUID is present in `~/.lunii-qt/official.db` and **absent** from `third-party.db`. Asset names are catalog-style (dino inventory / chapter / panorama, `fr_FR` locales). **Do not** treat this folder as an import target for deeper RE.

## Classic Lunii vs Flam-native

Filename peek (`find … -maxdepth 2 -type f`) on the single UUID, then stop:

| Marker | Present? |
|---|---|
| `main.lsf`, `info`, `key`, `version` | **Yes** (Flam-native) |
| `script/*.lsf`, `img/*.lif`, `sounds/` | **Yes** |
| Classic `ni` / `ri` / `si` / `li` / `bf` / `title.mgr` | **No** |

Rough file counts (this UUID only): **34** script, **186** img tree files, **402** sound files (~201 `.mp3` + ~201 `.mp3map`).

`file` / header magic (classification only, no export):

| Kind | Observation |
|---|---|
| `version` | 1 byte (`0x33`) |
| `info` / `key` / `main.lsf` / `script/*.lsf` | opaque `data` |
| `img/*.lif` | opaque `data` (expected LIFF-style; not opened) |
| `sounds/*.mp3` | **plain** playable MPEG/ID3 |
| `sounds/*.mp3map` | tiny opaque sidecars (~12 B sample) |

**Verdict:** On-disk story is **Flam-native** (`main.lsf` + `script/` + `img/` + `sounds/`), not classic Lunii index layout. Matches prior project notes for official catalog packs.

## Host tools

| Tool | Installed? | Version / path |
|---|---|---|
| **Lunii.QT** | Yes | `~/.local/bin/lunii-qt` → `~/.local/opt/lunii-qt/lunii-qt` (89M ELF, installed 2026-10-23). Desktop entry present. Embedded string **`1.3.1`** (likely app version; confirm in UI About if needed). Config: `~/.lunii-qt/` (`official.db`, `third-party.db`, cached `.mdf`). |
| **Story Studio** | Yes | `~/.local/bin/story-studio` → `~/.local/opt/story-studio/bin/story-studio`. Binary embeds **0.9.9**. Source checkout `~/src/story-studio` @ `v0.9.9-2-gda835ed` (fork `Yariminal/story-studio`). Upstream AppImage also kept under `~/.local/opt/story-studio/`. |

## Next step for owner (no custom pack yet)

Build a tiny custom classic pack in Story Studio, export Lunii ZIP, import with Lunii.QT onto this writable Flam, then USB-inspect **only the new UUID**.

Exact next command (after Story Studio export produces a ZIP path):

```bash
lunii-qt
# then: File → Import (Ctrl+I) → select the Story Studio Lunii ZIP → wait for Flam copy
```

Or, if the ZIP path is already known:

```bash
# GUI import is the supported path; launch Lunii.QT with Flam mounted:
lunii-qt
# File → Import / Ctrl+I → /path/to/your-custom-pack.zip
```

Full procedure: [`docs/first-pack-experiment.md`](first-pack-experiment.md). After import, re-run a safe inspect on **only** the new UUID (expect origin **T** in Lunii.QT; optionally **Hide** before Luniistore sync).

## Store path note

`/cursor/stores/self/` is **not** mounted on this self-hosted worker. This file lives in the Project agent store:

`/home/yariminal/.local/state/cursor/agent-stores/cursor_agent_stores/bc-64a35a8b-ef53-4b39-a2d2-0fc5e63ef41c/files/docs/flam-usb-inspect.md`
