<!-- Title: Personal Flam-native pack: how to mint firmware-accepted `key` on fw 2.x? -->

Hi — thank you for Flam.RE and the public tooling. I’m trying to author **personal / original** Flam-native packs (dummy Lua → LSF, LIFF, MP3) on my own device, **not** to rip or decrypt catalog content.

## Setup

- Firmware **2.4.2**
- Goal: a new-UUID personal hello pack under `str/<uuid>/` (ciphered `info` + `*.lsf`, plain LIFF/MP3)

## What already fails on this unit

1. **Classic STUdio → Lunii.QT** imports appear in the library but do not play (separate from native LSF; noted for context).
2. **Flam.RE-style “v3 trick”** on a fresh UUID:
   - on-disk `key` = `.mdf[0x4E:0x6E]`
   - `info` / `main.lsf` ciphered under the SNU-derived story materials documented in CIPHERING
   - Host round-trip decrypt of staged `info` worked; on device the Bibliothèque showed a **garbage title** and load stuck around **~1%**
3. That failure looks like the same class as [Lunii.QT #75](https://github.com/o-daneel/Lunii.QT/issues/75): Lunii.QT’s forged keyfile path is **not** a substitute for a firmware-accepted native wrap.

## Question

Public `tools/python/crypto_tool.py` has keys redacted, but comments / test markings suggest custom packs were authored successfully with a real wrap. For **fw 2.x**, what wrap method produces a firmware-accepted 32-byte `key` for a **new UUID** personal pack?

In particular:

- Is there any **host-side** way (without SWD / flash dump) to mint a wrap that fw 2.4.x will unwrap correctly?
- Did the v3 / `.mdf`-as-`key` path only apply to older firmware, or is there a different key/story assignment for 2.x?
- Any guidance you’re willing to share on how the redacted `crypto_tool.py` test packs got a working `key` would help a lot.

## Explicit non-goals

- Not asking for catalog decryption, device keys for ripping titles, or help circumventing paid library DRM.
- Happy to keep this scoped to original personal packs and public structure only.

Thanks again for the research and docs.
