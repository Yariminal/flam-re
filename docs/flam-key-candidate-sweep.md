# Flam device-key / wrap candidate sweep (host-only)

Date: 2026-10-26. Firmware **2.4.2**. Device mounted read/write at `/run/media/yariminal/FLAM` — **no canary written** (no offline win).

Oracle (owned files, structure only — no story dump):

| Input | Role |
|---|---|
| `.mdf` | Known PT/CT: `mdf[0x4E:0x7E]` = AES(device, SNU\|\|pad ×2) |
| `str/c103c95c-…/key` (32 B) | Device-wrapped `story_key\|\|story_iv` |
| `info` (128 B) | Story-AES ciphertext; success = title-like plaintext (e.g. contains “Emily”) |
| `main.lsf` first blocks | Optional “looks like Lua” check after a wrap hit |
| SNU `30224020004727`, `.mdf` fields | Candidate seeds |

**Success criterion:** materials that AES-unwrap `key` → story materials → decrypt `info` to printable title-like text.  
**Result: MISS** — **0** mdf PT recoveries, **0** unwrap→title hits, **0** direct-`info` hits.

## Method

1. Load device `.mdf`, Emily `key`/`info` (and `main.lsf` head only).
2. Build a **finite** candidate pool (hundreds–tens of thousands; not 2^128) from SNU, `.mdf`, hashes/KDFs, byte-order variants, Lunii.QT fw1/fw2 assignments, prior failures, Flam.RE docs/`crypto_tool.py` patterns.
3. Primary device-key oracle: for AES-128-CBC, `IV = Dec(K, C0) XOR P0` then verify full 48 B mdf plaintext (harness sanity-checked with a planted key).
4. On mdf match, unwrap Emily `key` and try story-material variants (plain / `reverse_bytes` / halves swapped) against `info`.
5. Secondary: treat candidates as story key+IV and decrypt `info` directly (global-story-key hypothesis).
6. Modes: CBC (default), ECB, CTR/CFB/OFB (pass 2), AES-256 with 32 B keys (pass 3).
7. Log every candidate id + pass/fail; no Emily plaintext written to the Project store.

Sources consulted: Flam.RE `CIPHERING.md` / `ANALYSIS.md` / `crypto_tool.py` (keys redacted), Lunii.QT `device_flam.py` fw1 vs fw2 key assignment, `aes_keys.reverse_bytes`, `lunii_generic_key`. No `~/.lunii-qt/*.keys`.

## Candidate count

| Pass | Scope | Rows logged |
|---:|---|---:|
| 1 | 546×16 B keys × derive-IV; ×46 explicit IVs; ECB; ~25k direct story pairs; 6 prior recipes | **51 354** |
| 2 | 137 keys × 30 alternate mdf PT layouts; HMAC/PBKDF2; lunii generic; CTR/CFB/OFB; more direct info | **22 468** |
| 3 | AES-256 (49×32 B keys); 32 B mdf-PT hypothesis | **307** |
| **Total** | | **~74 129** |

Unique 16 B key seeds (pass 1): **546**. IV seeds: **46**. Direct story pairs: **25 140**.

## Results table (by family)

| Family | N | Hits |
|---|---:|---|
| A — derive IV from mdf C0/P0 | 546 | 0 |
| B — explicit IV CBC (key×iv) | 25 116 | 0 |
| C — ECB mdf | 546 | 0 |
| D — direct story AES on `info` | 25 140 | 0 |
| E — prior failures (forge, mdf-as-key, SNU story, reverse/halves) | 6 | 0 |
| P2 — alternate mdf plaintext + KDF/HMAC + lunii generic | 22 468 | 0 |
| P3 — AES-256 / 32 B mdf PT | 307 | 0 |

All statuses **FAIL** (no `MDF_HIT_*`, no `HIT`, no `HIT_DIRECT_INFO`).

### Prior recipes reconfirmed fail

| Id | Detail |
|---|---|
| `prior_v3_trick_story_on_info` | `info` not title-like (ascii ~0.41) |
| `prior_mdf_ct_as_story_on_info` | ascii ~0.38 |
| `prior_forge_as_device_key_zero_iv` | mdf mismatch |
| `prior_forge_halves_as_key_iv` | mdf mismatch |
| `prior_snu_story_as_device` | mdf mismatch |
| `prior_mdf_ct_as_device` | mdf mismatch |

## Conclusion

Host-derivable materials from SNU / `.mdf` / UUID / FW string / VID:PID / Lunii generic key / finite SHA256·SHA1·MD5·HMAC·PBKDF2 / byte-order and nibble swaps **do not** recover this unit’s device AES key, nor decrypt Emily `info` as a global story key under the tried layouts.

This aligns with:

- Flam.RE: device key ✅ only via invasive RE (redacted in public tools); v3 trick is a **wrap reuse**, not key recovery.
- On-device **v3-trick canary fail** on 2.4.2 ([`flam-key-experiment-results.md`](flam-key-experiment-results.md)).
- Lunii.QT [#75](https://github.com/o-daneel/Lunii.QT/issues/75) forge/`keyfile` class.

**Personal native packs remain blocked** without a real device wrap (author insight, app keystore/`*.keys`, or out-of-scope SWD).

**Next (no device write):** wait on [Flam.RE #1](https://github.com/o-daneel/Flam.RE/issues/1) / author contact; keep official/FAH/Mon Studio paths; do **not** deploy canaries until an offline candidate clearly wins.

Evidence log (ids + status only): `internal/flam-key-candidate-sweep-log.md`. No `internal/flam-device-key-method.md` (no HIT).
