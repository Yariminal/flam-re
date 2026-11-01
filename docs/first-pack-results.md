# First pack results — Flam RE Tiny Choice

Custom STUdio ZIP → Lunii.QT `FlamDevice.import_story` → USB inspect of **only** the new UUID. No official pack content copied or decrypted.

## Host / tools

| Item | Value |
|---|---|
| Host OS | Omarchy (Arch Linux), kernel `6.19.8-arch1-3-surface` |
| Flam mount | `/run/media/yariminal/FLAM` (`/dev/sda1` vfat) |
| Flam firmware | **2.4.2** (`.mdf`) |
| Import path | Lunii.QT **Python API** (`pkg.api.device_flam.FlamDevice.import_story`) — same code as GUI File→Import. Clone commit `c8afe43` under `~/flam-re/luniiqt-tools/Lunii.QT`. |
| Authoring | Hand-built STUdio archive; not Story Studio GUI export |
| FFmpeg | `n9.0.2` (sine-tone MP3s @ 44100 Hz mono) |

## Pack

| Field | Value |
|---|---|
| Title | **Flam RE Tiny Choice** |
| UUID | `89bb536b-dd44-472e-bfe7-ec7a20a35c4e` |
| Graph | Cover → Choice → Option A\|B → Ending A\|B |
| ZIP (kept) | `~/flam-re/Flam-RE-Tiny-Choice.zip` (~517 KB v3); `media/Flam-RE-Tiny-Choice.zip` |
| Source (kept) | `internal/flam-re-tiny-choice/` |

Distinct from official catalog UUID `c103c95c-a852-4d8f-9c03-82f3814b572d`.

## Play status — final

| Version | Result |
|---|---|
| **v1** | Title → black / no choices |
| **v2** | Title → black, **no audio** (AES ciphered) |
| **v3** | **Load failure** — “loading the story” then fail (`debug_plain` plaintext assets) |

**Conclusion:** classic STUdio→Lunii.QT path is **not viable for playback** on this fw **2.4.2** unit. Diagnosis: [`tiny-choice-black-screen.md`](tiny-choice-black-screen.md). Next options: [`flam-native-path.md`](flam-native-path.md).

## Device purge (2026-10-26, post–v3 retest)

| Step | Result |
|---|---|
| Motive | Restore healthy Emily-only Bibliothèque; keep ZIP/sources on host |
| `list` | Rewritten to official UUID only; `list.hidden` empty |
| `str/89bb…` | Removed |
| `usr/0/89bb….save` | Removed; `library.cache` deleted for rebuild |
| Official | Untouched (`main.lsf` present; no content dump) |
| Flush | `sync` ×2; `udisksctl` unmount/mount verify |

### Post-remount verify

| Check | Result |
|---|---|
| `etc/library/list` | **exactly 1** UUID: `c103c95c-…` |
| `list.hidden` | empty (0 B) |
| `str/` | Emily only; Tiny Choice **absent** |
| `89bb` leftovers | **0** |
| Emily `main.lsf` | present, 67424 B |
| Host ZIP/source | still at `~/flam-re/…` + `media/` + `internal/flam-re-tiny-choice/` |

## Import history (succeeded; playback did not)

`IMPORT_OK=True` for v1–v3. Layout always **classic** indices + Flam sidecars — never Flam-native.

### v3 on-device tree (before purge; `debug_plain`)

```
str/89bb536b-dd44-472e-bfe7-ec7a20a35c4e/
  info, key, ni (plain), li/ri/si (plain — expected cipher on fw)
  img/thumbnail.lif (liff)
  rf/000/*  BM @0 (plain)
  sf/000/*  ff fb @0 CBR128 (plain)
```

Autopsy: plaintext vs firmware cipher expectation → early load abort; see diagnosis doc.

## Layout verdict

**Classic Lunii index layout on Flam, with Flam sidecars — not Flam-native.** Listing worked; playback never did on 2.4.2 via Lunii.QT.

## ZIP reuse (autopsy only — do not re-import without new theory)

- `~/flam-re/Flam-RE-Tiny-Choice.zip`
- Project store: `media/Flam-RE-Tiny-Choice.zip`
- Editable source: `internal/flam-re-tiny-choice/`

## Errors / notes

- Hide/unhide VFAT storms: [`flam-library-bug.md`](flam-library-bug.md).
- Community parallel: [Lunii.QT #61](https://github.com/o-daneel/Lunii.QT/issues/61).
- No further classic STUdio variants unless a high-confidence fix differs from v1–v3 (AES / autoplay / CBR / `debug_plain`).
