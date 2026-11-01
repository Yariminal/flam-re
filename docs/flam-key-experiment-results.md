# Flam key experiment results (fw 2.4.2)

Date: 2026-10-26. Decision source: [`flam-key-options.md`](flam-key-options.md).

## Decision executed

**2b — `.mdf` known-plaintext wrap reuse (Flam.RE “v3 trick”)** on a new personal UUID.  
**Result: FAILED** on firmware **2.4.2** (owner photo + play-test).

Not run: pure Lunii.QT forged-key canary (redundant — same auth-fail class).  
Not run: SWD/JTAG raw device-key dump (**stop-and-ask**).

## What was built

| Item | Value |
|---|---|
| UUID | `dc0bf8f5-1863-4809-a767-f6a7f1525d65` |
| Staging | `internal/flam-native-hello/` (dummies only; retained on host) |
| `key` | `mdf[0x4E:0x6E]` (32 B) — **not** fw-2 forge |
| Story AES | SNU-derived `hexlify(SNU)\|\|\\x00\\x00` / `8×\\x00\|\|hexlify(SNU)[:8]` |
| Cipher | AES-128-CBC, zero-pad; Flam path (no `reverse_bytes`) |
| `info` plaintext | `RE Hello Canary\\nscript/local.lsf` |
| Lua | Dummy `main.lua` → optional `audio.play("hello.mp3")` then `goto_library()` |
| Assets | Dummy LIFF thumbnail, 1.2 s sine MP3, 12 B `mp3map` |

Host round-trip: decrypt of staged `info` with those story materials recovered the title string. That does **not** prove firmware unwrap matches.

## Owner play-test (fail)

After eject + library open on fw **2.4.2**:

| Observation | Value |
|---|---|
| Bibliothèque title | Garbled: `o:xZ'_2aKaMD(` (not “RE Hello Canary”) |
| Load | Stuck at **1%** |
| Emily | Still visible (green cover) — untouched |

Interpretation: firmware did **not** unwrap `key`=`mdf[0x4E:0x6E]` to the SNU-shaped story materials the host used. Same auth-fail class as [Lunii.QT #75](https://github.com/o-daneel/Lunii.QT/issues/75) (garbage title / load fail). Cached `library.cache` title bytes were opaque garbage (consistent with failed `info` decrypt).

**Personal native packs remain blocked** on this unit via the v3 trick.

## Device purge (post-fail)

Canary **removed** completely; Emily-only verified:

- Deleted `str/dc0bf8f5-1863-4809-a767-f6a7f1525d65/`
- `etc/library/list` → Emily UUID only (`c103c95c-a852-4d8f-9c03-82f3814b572d`)
- Deleted `usr/0/dc0bf8f5-….save`, `.prog`, and `usr/0/library.cache` (rebuild on next boot)
- `find` for `dc0bf8f5*` → none; Emily `key`/`info`/`main.lsf` still readable
- `sync` ×2

No broken canary left on device. Host staging under `internal/flam-native-hello/` kept for method notes only.

## Host recovery research (option 2a)

- No `*.keys` under `~/.lunii-qt` (only `.mdf` backup + DBs).
- Flam.RE marks device key ✅ but redacts `crypto_tool.py`; README points at SWD/JTAG for deep RE.
- Known plaintext (SNU×2) + ciphertext (`.mdf[0x4E:]`) does **not** recover AES-128 device key on the host.

## Outcome

| Question | Answer |
|---|---|
| Personal native packs unblocked? | **No.** v3 trick **failed** on fw 2.4.2. |
| Raw device key recovered? | **No.** |
| Canary on device? | **No** (purged; Emily-only). |
| Next | Ranked remaining paths in [`flam-key-options.md`](flam-key-options.md) / [`flam-native-path.md`](flam-native-path.md). Best non-SWD ask: **Flam.RE author contact** (how custom packs were signed OK with redacted tools). |

Method detail (no raw device key): `internal/flam-native-hello/METHOD.md`.

## Expanded host-only candidate sweep (2026-10-26)

Follow-up after v3-trick fail: systematic offline sweep of device-key / wrap / story-AES candidates against Emily `key`+`info` and `.mdf` known PT/CT. **No device writes.**

| Metric | Value |
|---|---|
| Candidates logged | **~74 129** |
| mdf PT recoveries | **0** |
| unwrap → title-like `info` | **0** |
| direct `info` decrypt hits | **0** |
| HIT? | **No** |

Pools included prior failures (forge, `mdf[0x4E:0x6E]`, SNU story materials, reverse/halves), Flam.RE / Lunii.QT fw1↔fw2 inversion patterns, hash/KDF/HMAC/PBKDF2 of SNU·mdf·UUID, byte-order/nibble swaps, ECB/CTR/CFB/OFB, AES-256. Device key is **not** host-derivable from these finite seeds.

Full write-up: [`flam-key-candidate-sweep.md`](flam-key-candidate-sweep.md). Log: `internal/flam-key-candidate-sweep-log.md`. No `flam-device-key-method.md` (no HIT).

## Carrier-key assessment (2026-10-27) — still blocked

Context: scarlaty on [Flam.RE #1](https://github.com/o-daneel/Flam.RE/issues/1) + [Lunii.QT #75](https://github.com/o-daneel/Lunii.QT/issues/75); peer repo [scarlaty/flam-player](https://github.com/scarlaty/flam-player) (`docs/flam-carrier.md`). Full notes: [`flam-re-issue1-followup.md`](flam-re-issue1-followup.md).

| Idea | Result on fw **2.4.2** |
|---|---|
| Copy Emily’s 32 B wrapped `key` into a **new UUID** | Not enough by itself (firmware still unwraps to Emily’s story materials). |
| Re-cipher **our** dummy `info`/`*.lsf` under Emily’s story AES key‖IV | **Blocked** — story key (`bt`) unknown; no on-disk `bt`; unwrap needs device AES (host MISS). |
| flam-player carrier path | Documented / validated for **fw 1.x** when `bt` is user-supplied. **Not** a supported 2.x unlock; their 2.x path is mdf wrap (same class as our failed v3 trick). |
| Device write / Emily prose-audio rip | **Not done** (constraint). |

**Personal native packs remain blocked** on this unit. No new canary deployed.
