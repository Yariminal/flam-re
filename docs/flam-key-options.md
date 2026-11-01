# Flam-native key options — comparison & decision (fw 2.4.2)

Research (2026-10-26). Sources: [Flam.RE](https://github.com/o-daneel/Flam.RE) `CIPHERING.md` / `ANALYSIS.md` / `tools/python/crypto_tool.py`, [Lunii.QT #75](https://github.com/o-daneel/Lunii.QT/issues/75), `device_flam.py` `__mdf_parse`, on-device `.mdf` + Emily `key` (structure only). **No Emily content.**

## Model (shared)

| Material | Role |
|---|---|
| **Device key + IV** (AES-128-CBC) | Wraps on-disk `key`; ciphers `.mdf` second block (SNU×2). Bound to this unit; not published. |
| **Story key + IV** (AES-128-CBC) | Ciphers `info` + `*.lsf`. |
| **On-disk `key` (32 B)** | `story_key \|\| story_iv` under device AES. Firmware unwraps; Lunii.QT forged `keyfile` is not a substitute ([#75](https://github.com/o-daneel/Lunii.QT/issues/75)). |

### `.mdf` layout (this unit, 126 B)

| Offset | Content |
|---|---|
| `0x00` | `01 00` |
| `0x02` | FW string (`2.4.2-bc9881da` + NUL pad) — 48 B field |
| `0x32` | SNU ASCII `30224020004727` + pad — 24 B |
| `0x4A` | USB VID/PID `3a309e81` |
| `0x4E` | **48 B ciphered** = AES(device, SNU\|\|pad \|\| SNU\|\|pad) |
| `0x4E:0x6E` | First **32 B** of that ciphertext (candidate wrap for a 32 B `key`) |

Emily `key` ≠ `mdf[0x4E:0x6E]` ≠ Lunii.QT fw-2.x forge (`hexlify(SNU)\|\|10×0\|\|hexlify(SNU)[:8]`).

### Lunii.QT inversion on fw 2.x

```text
fw 1.x:  keyfile = mdf[0x4E:0x6E] (ciphertext) ; story = SNU-derived plaintext
fw 2.x:  keyfile = SNU-derived plaintext forge   ; story = mdf[0x4E:0x6E] bytes
```

[#75](https://github.com/o-daneel/Lunii.QT/issues/75) A/B: writing forge/`keyfile` + re-cipher under SNU story materials → garbage title + load fail; restoring official wrapped `key` restores play. Hypothesis: firmware unwraps `key` with device AES — forge plaintext unwraps to garbage.

### Flam.RE “v3 trick” (host-side, no raw device key)

`CIPHERING.md` attack path: use `.mdf` known-plaintext (SNU×2) so a **fake** story key that is already device-wrapped is known even when device key is not:

1. Put `key` = `mdf[0x4E:0x6E]` (ciphertext that decrypts to SNU-shaped 32 B).
2. Cipher `info` / `*.lsf` with that known plaintext as `story_key\|\|story_iv`:
   - `story_key = hexlify(SNU) + \\x00\\x00` (16 B)
   - `story_iv  = 8×\\x00 + hexlify(SNU)[:8]` (16 B)
3. Firmware unwrap → same SNU materials → title/scripts decrypt if padding/CBC match Flam.RE `crypto_tool.py` (AES-CBC, zero-pad).

`crypto_tool.py` redacts real keys but writes a prebuilt `key` blob + AES-CBC `info`/`lua`; custom test packs marked OK there imply a working wrap (real device wrap **or** this trick). Raw device key recovery from PT/CT alone is **not** feasible (AES-128); Flam.RE’s ✅ device key came from invasive RE, not host math.

---

## Option 1 — Forged-key Flam-native canary

| Axis | Assessment |
|---|---|
| **What** | New UUID; `key` = Lunii.QT fw-2 forge; `info`/`main.lsf` under `.mdf` “story” bytes or SNU materials; dummy LIFF/MP3/Lua. |
| **Effort** | Low (hours of packaging). |
| **Risk** | Low if new UUID + careful `etc/library/list` edit + VFAT `sync`/verify; Emily untouched. Remove after. |
| **Info gain** | Confirms fw **2.4.2** behaves like [#75](https://github.com/o-daneel/Lunii.QT/issues/75) (expected **fail**: garbage title / chargement bounce). Does **not** unlock authoring. |
| **Unlock personal native?** | No (negative control). |
| **Depends on unpublished keys?** | No. |

## Option 2 — Device-key path for personal dummies

Split into two sub-paths:

### 2a — Raw device-key recovery

| Axis | Assessment |
|---|---|
| **What** | Extract AES-128 device key+IV (flash/SWD/UART), then wrap arbitrary story keys. |
| **Effort** | High; HW. |
| **Risk** | Jailbreak / brick / catalog DRM wall — **out of scope** unless only path left; **stop and ask** before SWD. |
| **Info gain** | Full wrap capability if successful. |
| **Host-side chance** | Negligible (known PT/CT on `.mdf` does not yield AES key). |
| **Unlock personal native?** | Yes, if recovered. |
| **Depends on unpublished keys?** | Recovers the unpublished secret. |

### 2b — `.mdf` known-plaintext wrap reuse (“v3 trick”)

| Axis | Assessment |
|---|---|
| **What** | New UUID; `key` = `mdf[0x4E:0x6E]`; cipher under SNU-derived story materials; dummy assets only. |
| **Effort** | Low–medium (same packaging as canary; correct key assignment). |
| **Risk** | Same as option 1 (library pollution only). No Emily unwrap; no firmware touch. |
| **Info gain** | High: if title readable / load progresses → personal native packs **unblocked** without raw device key. If [#75]-style fail → fw 2.4.2 rejected mdf-as-key (document; fall back). |
| **Success chance** | Non-trivial — Flam.RE documents this as the info-forge path; fw-1.x Lunii.QT used the same key/story assignment; fw-2.x host tool **inverted** it (likely why forge fails). |
| **Unlock personal native?** | Yes on success (shared SNU story materials for all such packs; fine for personal dummies). |
| **Depends on unpublished keys?** | **No** — uses public structure of `.mdf` + SNU. |

---

## Decision (executed)

**2b (v3-trick personal hello)** was the primary experiment — **FAILED** on fw **2.4.2** (owner: garbled title `o:xZ'_2aKaMD(`, load stuck at **1%**; Emily OK). Canary purged. Details: [`flam-key-experiment-results.md`](flam-key-experiment-results.md).

Implication: host-side mdf-as-`key` + SNU story AES is **not** accepted by this firmware (same class as [#75](https://github.com/o-daneel/Lunii.QT/issues/75)). Personal native packs stay blocked without a real device wrap.

Do **not** SWD/jailbreak without an explicit owner ask. Skip pure-forge canary (expected same fail; low info).

---

## Remaining paths (ranked after 2b fail)

| Rank | Path | What it buys | Notes |
|---:|---|---|---|
| **1** | **Contact Flam.RE author** (o-daneel) — how public `crypto_tool.py` test packs got a firmware-accepted `key` with redacted secrets; whether any **host-side** wrap exists for fw 2.4.x | Highest non-invasive info gain; may unlock personal dummies without HW | Social / research ask; no Emily dump |
| **2** | **Official studio / FAH / Mon Studio** — vendor-accepted personal or owned catalog paths | Content that plays today; FAH→Flam as classic control | Linear / catalog limits; not full LSF backpack |
| **3** | **Deeper device-key recovery without SWD** — only if a *new* host lead appears (e.g. leaked `.keys`, Studio/app keystore, UART log with wrap material). Known PT/CT on `.mdf` alone remains **insufficient** | Would unlock arbitrary wraps | Currently **no concrete lead**; do not invent HW steps |
| **4** | **Accept the wall** — keep AI workflow on paths that work (Mon Studio / FAH); Flam-native LSF research stays documentation-only | Honest scope for personal full-feature packs | Revisit only if (1) or (3) opens |
| **5** | **SWD / flash dump for raw device key** | Full wrap capability if successful | **Out of scope** until owner explicitly reopens; brick / jailbreak risk |

Results: [`flam-key-experiment-results.md`](flam-key-experiment-results.md). Path overview: [`flam-native-path.md`](flam-native-path.md).
