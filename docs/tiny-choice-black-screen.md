# Tiny Choice — classic STUdio→Flam blocked (fw 2.4.2)

Owner play-tests on Flam fw **2.4.2**, UUID `89bb536b-dd44-472e-bfe7-ec7a20a35c4e`:

| Version | On device | Result |
|---|---|---|
| **v1** | Cover `autoplay:false`, quiet sine, AES | Title → **black screen**, no choices |
| **v2** | Cover `autoplay:true`, brighter/louder, AES | Same — title → black, **no audio** |
| **v3** | CBR 128 kb/s loud MP3s + **`debug_plain`** (no AES on `li`/`ri`/`si`/`rf`/`sf`) | **Load failure** — short “loading the story” notification, then fails (never reaches title) |

**Verdict:** classic STUdio → Lunii.QT → Flam playback is **not viable** on this fw **2.4.2** unit after v1–v3. Do **not** re-import another classic variant without a high-confidence fix different from these three levers.

Pack **purged** from device 2026-10-26 (Emily-only Bibliothèque). Host ZIP/sources kept for autopsy.

## Why v3 fails to load (autopsy)

On-device pack was **readable** (not a VFAT ghost): `str/89bb…/` listed, all files openable, `list` had 2 UUIDs.

| Check | Finding |
|---|---|
| VFAT ghost? | **No** for this UUID — dirs `drwx…`, assets readable. Leftover `FSCK*.REC` from earlier storms still present; unrelated to this pack’s openability. |
| `debug_plain` mismatch | **Yes — most likely early-fail cause.** Firmware classic path expects **ciphered** `li`/`ri`/`si` + AES headers on `rf`/`sf`. v3 left them **plaintext** (`li`=`[1..5]` ints; `ri`/`si`=`000\COVER…` ASCII; `rf`=`BM`@0; `sf`=`ff fb`@0). v2 (ciphered) at least opened to title; v3 fails **during load** — consistent with decrypt/validate rejecting plaintext as garbage. |
| `ni` | Always plain (Lunii.QT never ciphers `ni`); 776 B / 6 nodes — not the differentiator. |
| Host assets | CBR128 MP3s + BMP RLE valid on disk; graph Cover AUTO=1 — never reached if load aborts. |
| Official Emily | Flam-native only (`main.lsf`/`script/`/`img`/`sounds`) — **no** classic indices; catalog never exercises this path. |

So: v3 did **not** prove “cipher was the problem”; it made load **worse** by removing cipher the fw likely requires, while v1/v2 already proved **ciphered classic still does not play**.

## Root cause (revised, final for classic path)

**Listing ≠ playback.** Title/thumb come from plain `info` + `img/thumbnail.lif`. Story engine needs classic indices + media; on this unit that path never yields audio/images for Lunii.QT STUdio imports.

| Factor | Evidence |
|---|---|
| Host crypto OK (v2) | `reverse_bytes(.mdf story_key/iv)` decrypt → valid BMP/`ff fb`; AES header round-trip bit-exact |
| Graph OK | Cover AUTO=1 OK=1; Choice WHEEL=1 OK=1; names match files |
| Community | [Lunii.QT #61](https://github.com/o-daneel/Lunii.QT/issues/61) (fw **2.1.5**): STUdio→Flam import OK, title OK, **no story audio** — open |
| Official FAQ | FAH→Flam via **official app** ≠ validation of third-party STUdio layout |

## Structure contrast (names/sizes/magic only — no Emily dump)

| | Tiny Choice (classic) | Emily (official) |
|---|---|---|
| Engine | `ni`/`li`/`ri`/`si` + `rf/` + `sf/` | **absent** |
| Native | no `main.lsf` | `main.lsf` + `script/*.lsf` + `version` |
| Media | RLE4 BMP / MP3 under `rf`/`sf` | plain `img/*.lif` (`liff`), plain `sounds/*.mp3` |
| `info` | plain ASCII | ciphered opaque |
| `key` | 32 B SNU forge | 32 B device-wrapped |

## Classic-on-Flam viability (2.4.2) — closed

| Path | Verdict |
|---|---|
| Lunii.QT STUdio → classic indices | **Blocked** on this device (v1/v2 no playback; v3 load fail; #61) |
| Official FAH→Flam (Lunii app) | Untested — different packaging; ranked next option if owner has FAH titles |
| Flam-native custom | Still gated on LSF/`key` wrap — see [`flam-native-path.md`](flam-native-path.md) |

## Device state after purge

- `etc/library/list` = official UUID only  
- `str/` = Emily only; Tiny Choice folder removed  
- `usr/0/89bb….save` + `library.cache` removed  
- Host keep: `~/flam-re/Flam-RE-Tiny-Choice.zip`, `media/Flam-RE-Tiny-Choice.zip`, `internal/flam-re-tiny-choice/`

## Owner

Safe eject → power-cycle → Bibliothèque should show **Emily only**. No further classic Tiny Choice imports unless a **new** theory (e.g. official-app FAH control pack).
