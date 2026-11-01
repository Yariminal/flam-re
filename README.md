# flam-re

Research notes and host-side tools for **personal Flam-native story authoring** on Lunii Flam firmware **2.4.2**.

## Status

**fw 2.x personal mint is solved** (confirmed on stock fw `2.4.2`). The device AES key is **not recovered and not needed** for authoring.

Firmware derives each story’s AES key/IV by encrypting the on-disk 32-byte `key` file under the device key (AES-128-ECB, block-independent). Set:

```text
key = SNU32 = (SNU24 || SNU24)[0:32]
```

so `story_key/iv = .mdf C0/C1` (raw bytes already on the VFAT root). Cipher `info` and `*.lsf` with AES-128-CBC (zero-pad) under C0/C1; leave media plain; append the UUID to `etc/library/list`; delete `usr/0/library.cache`.

Write-up: [`docs/fw2-key-wrap.md`](docs/fw2-key-wrap.md)  
Upstream thread: [Flam.RE #1 comment](https://github.com/o-daneel/Flam.RE/issues/1#issuecomment-6552957337)

## Constraints

- **No CFW**, no firmware flashing, no hardware exploits
- **No catalog rip** — no official story prose/audio/scripts redistributed
- Tools read `.mdf` / SNU from a **mounted personal device** at runtime; this repo does not ship device secrets or raw `.mdf` dumps

## Layout

```text
docs/                 Project research notes (mint, packs, RE findings)
flamtool/             Host mint/pack/battery helpers (Python + pycryptodome)
stories/lost-button/  Original homebrew sample (Lua + manifest + small assets)
requirements.txt      pycryptodome
```

## How to pack (fw 2.4.2)

1. Author a flam-homebrew project (see [scarlaty/flam-player](https://github.com/scarlaty/flam-player) `skills/flam-homebrew`) and build a `.plain.pk`.
2. Mount the Flam USB (VFAT). Confirm `$FLAM_ROOT/.mdf` exists.
3. Install with the host mint tooling:

```bash
python3 -m venv .venv && . .venv/bin/activate
pip install -r requirements.txt
python flamtool/pack.py "$FLAM_ROOT" /path/to/story.plain.pk
sync
# then udisksctl unmount + power-off; power-cycle Flam into the library menu
```

Bare single-Lua mint: `flamtool/mint.py` (prefer `pack.py` for real modules).  
Cleanup test UUIDs: `flamtool/cleanup.py`.

Longer workflow notes: [`docs/author-mint-play.md`](docs/author-mint-play.md).

## Docs index (high signal)

| Doc | Topic |
|---|---|
| [`fw2-key-wrap.md`](docs/fw2-key-wrap.md) | Solved mint model |
| [`author-mint-play.md`](docs/author-mint-play.md) | Author → mint → play |
| [`lost-button.md`](docs/lost-button.md) | Device-proven original story |
| [`ai-flam-pipeline.md`](docs/ai-flam-pipeline.md) | AI → pack pipeline sketch |
| [`flam-native-lsf.md`](docs/flam-native-lsf.md) | Flam-native LSF / pack shape |
| [`flam-re-issue1-solved-reply.md`](docs/flam-re-issue1-solved-reply.md) | Text posted to Flam.RE #1 |
| [`project-context.md`](docs/project-context.md) | Project status overview |

## License / provenance

Research and original tooling by [Yariminal](https://github.com/Yariminal). Official Flam/Lunii firmware and catalog content remain their owners’. Homebrew sample under `stories/lost-button/` is original.
