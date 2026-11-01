# Custom pack sidecars — `info` and `key`

Scope: **only** our imported pack UUID `89bb536b-dd44-472e-bfe7-ec7a20a35c4e` under `str.hidden/…` (fw **2.4.2**). No official-pack key material or ciphered `info` contents.

Written by Lunii.QT `FlamDevice` on STUdio/classic import (`__write_info`, `keyfile` copy). Sources: on-disk hex dump 2026-10-26; [Flam.RE ANALYSIS](https://github.com/o-daneel/Flam.RE/blob/main/ANALYSIS.md) / [CIPHERING](https://github.com/o-daneel/Flam.RE/blob/main/CIPHERING.md); Lunii.QT `pkg/api/device_flam.py` @ `c8afe43`.

## `info` — 73 bytes, **plain ASCII**

Path: `…/89bb536b-dd44-472e-bfe7-ec7a20a35c4e/info`

Exact contents (no trailing newline after last line):

```
Flam RE Tiny Choice
Flam RE Tiny Choice
0
Flam RE Tiny Choice
No authors.
```

| Line | Value | Role (from Lunii.QT `__write_info`) |
|---:|---|---|
| 1 | story name (unidecode) | Title |
| 2 | story name again | Duplicate / secondary label |
| 3 | `0` | Constant written by importer (meaning undocumented; not a version file) |
| 4 | story name again | Third name field |
| 5 | author string | From third-party DB / import metadata (`No authors.` here) |

Hex (full file):

```
46 6c 61 6d 20 52 45 20 54 69 6e 79 20 43 68 6f
69 63 65 0a 46 6c 61 6d 20 52 45 20 54 69 6e 79
20 43 68 6f 69 63 65 0a 30 0a 46 6c 61 6d 20 52
45 20 54 69 6e 79 20 43 68 6f 69 63 65 0a 4e 6f
20 61 75 74 68 6f 72 73 2e
```

### vs Flam.RE (official Flam-native)

| | **Our classic import** | **Flam.RE (native catalog)** |
|---|---|---|
| Cipher | **None** — readable text | Ciphered with **story** AES key |
| Length | Variable plain text | Variable opaque |
| Documented fields | Empirically 5 lines from Lunii.QT | “Mysterious”; title (and maybe description) suspected after decrypt |
| Purpose on device | Library / selection metadata for imported packs | Same role, different encoding |

Flam.RE CIPHERING also notes: missing/bad keys → story still selectable but **info incorrectly deciphered** (native path). Our plain `info` sidesteps that for classic imports.

## `key` — 32 bytes (`0x20`), **forged fw-2.x keyfile**

Path: `…/key`

Hex:

```
33 30 32 32 34 30 32 30 30 30 34 37 32 37 00 00
00 00 00 00 00 00 00 00 33 30 32 32 34 30 32 30
```

ASCII view: `30224020004727` + 10× `00` + `30224020`.

### Construction (Lunii.QT, fw main **not** `1.x`)

From `__mdf_parse` when `fw_main` does not start with `"1."`:

```text
keyfile = hexlify(SNU)  ||  10×0x00  ||  hexlify(SNU)[:8]
```

For this device SNU string `30224020004727`:

| Offset | Len | Bytes | Meaning |
|---:|---:|---|---|
| 0 | 14 | `30224020004727` | ASCII hex of SNU |
| 14 | 10 | `00…00` | Padding |
| 24 | 8 | `30224020` | First 8 ASCII hex chars of SNU |

Same 32-byte blob is written into every classic (and many Flam backup) import as `key` on this device (`fp.write(self.keyfile)`).

AES story key/IV used for **ciphering classic `li`/`ri`/`si` and first `0x200` of `rf`/`sf`** are read from `.mdf` (separate from this on-disk `key` file shape) — see Lunii.QT `story_key` / `story_iv` after `seek(0x4E)` on fw 2.x. Do not confuse the forged **auth token file** with the in-memory AES material.

### vs Flam.RE (official Flam-native)

| | **Our classic import** | **Flam.RE (native)** |
|---|---|---|
| Size | `0x20` | `0x20` |
| Flam.RE claim | N/A (classic path) | Story AES key + IV **ciphered with device key** (`uint key[4]; uint iv[4]`) |
| Our bytes | Deterministic SNU-derived **plaintext forge** (Lunii.QT “decipher trick” / fw-2 import) | Opaque ciphertext (device-bound); **not examined here** |
| Same for all stories? | Yes on this device for Lunii.QT imports (`keyfile` reused) | Flam.RE: “Key file can be the same for all stories” (fact) |

**Takeaway:** Size matches Flam.RE’s `0x20` auth file, but **encoding differs**: community native packs wrap real story key+IV; our custom classic pack gets Lunii.QT’s SNU-padded forge so fw 2.x accepts classic AES headers. That does **not** by itself prove we can mint a native LSF pack auth blob.

## Related files (same UUID, not sidecars)

| File | Size | Note |
|---|---:|---|
| `ni` | 688 | Plain classic node index |
| `li` / `ri` / `si` | 16–48 | Ciphered (full file ≤ 0x200) |
| `rf/000/*`, `sf/000/*` | ~3–12K | AES first `0x200`; RLE4/MP3 tails plain |
| `img/thumbnail.lif` | 24357 | Plain LIFF (`liff` magic) |

Absent vs native: `main.lsf`, `version`, `script/`, `sounds/`.

## Implications for Flam-native authoring

1. Plain multiline `info` is enough for Lunii.QT classic imports; native catalog expects **ciphered** `info`.
2. Reusing the forged `keyfile` is the supported community path for **classic-on-Flam** on fw 2.x.
3. A true Flam-native personal pack likely needs either (a) the same forge accepted for LSF (unproven), or (b) a real device-key wrap of a new story key — still an open research item, without using official pack keys as source material.
