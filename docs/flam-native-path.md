# Path: classic blocked → next options (fw 2.4.2)

**Status (2026-10-26):** Classic STUdio → Lunii.QT import **lists** on fw **2.4.2** but **does not play**. v1/v2: title → black, no audio. v3 (`debug_plain`): **load failure** (“loading the story” then fail). Matches [Lunii.QT #61](https://github.com/o-daneel/Lunii.QT/issues/61). Host AES of our assets was fine; plaintext-on-device made load **worse**. Official Emily is **Flam-native only** (no `ni`/`li`/`ri`/`si`).

**Classic path: BLOCKED** for the AI workflow on this unit. Tiny Choice **purged** from device (Emily-only). ZIP/sources kept on host. Do not re-import classic variants without a high-confidence new theory.

**Flam-native LSF research (option C) advanced:** layout + cipher model + partial Lua API documented in [`flam-native-lsf.md`](flam-native-lsf.md). Host `.mdf` story_key/iv **does not** unwrap Emily `info`/`*.lsf`. Official `key` ≠ Lunii.QT forged `keyfile`. Dummy hello **blocked** on device-key wrap ([Lunii.QT #75](https://github.com/o-daneel/Lunii.QT/issues/75) model); skeleton plan only — [`internal/flam-native-skeleton-plan.md`](../internal/flam-native-skeleton-plan.md). No Emily content ripped.

Full Flam features (backpack, map, traits, rewards) live in Flam-native **LSF**, not the classic graph — classic would not unlock them even if playback were fixed.

## Ranked next options (offer to owner)

| Rank | Option | What it buys | Notes |
|---:|---|---|---|
| **A** | Official Lunii app / FAH → Flam switch packs (if owner has any FAH titles) | Control: does **vendor-packaged** classic play on this fw? Separates “firmware classic broken” vs “Lunii.QT STUdio packaging broken” | Owner-owned titles only; no STUdio ZIP |
| **B** | Mon Studio Lunii — linear personal audio | Personal content that Flam accepts today without classic indices | Linear only; no branching / backpack |
| **C** | Flam-native LSF research (public Flam.RE + our sidecars + black-box UI) **without ripping Emily** | Path toward backpack/map/rewards once `key` wrap + Lua API are known | **v3-trick FAILED** on 2.4.2 (garbled title + 1% load); personal `key` wrap still blocked; schema incomplete |

### After v3-trick fail — remaining ranks

| Rank | Path | Notes |
|---:|---|---|
| **1** | Contact Flam.RE author (host-side wrap for fw 2.4.x?) | Best non-invasive next ask |
| **2** | Official studio / FAH / Mon Studio | Plays today; limited features |
| **3** | Deeper device-key recovery **without SWD** if a new host lead appears | None known yet; PT/CT alone insufficient |
| **4** | Accept the wall | AI workflow on A/B; native docs-only |
| **5** | SWD / flash for raw device key | Owner ask only |

## Longer research ladder (least invasive)

| Rank | Approach | Invasion |
|---:|---|---|
| **1** | Public docs — [Flam.RE](https://github.com/o-daneel/Flam.RE), [Lunii.QT](https://github.com/o-daneel/Lunii.QT), STUdio | None |
| **2** | Community issues (no pack dumps) — e.g. #61, #75 | None |
| **3** | Analyze **our** custom sidecars/indices only | Own files |
| **4** | Black-box UI of official pack on device (no USB content dump) | Observation |
| **5** | LIFF round-trip on **our** thumbnail | Own assets |
| **6** | Mint personal Flam-native skeleton **after** documented lawful `key` wrap + enough Lua API | Packaging RE — blocked |
| **7** | Firmware / SWD / DRM unwrap of paid catalog | **Out of scope** |

## What is still blocked without an LSF spec

- Clean public Lua framework sources (`plain_scripts` heavily corrupted / redacted keys in Flam.RE tools).
- Documented authoring of Flam-native scripts firmware accepts as *new* personal packs.
- Stable minting of firmware-accepted per-story `key` for a **new** Flam-native UUID (official wrap ≠ Lunii.QT forged fw-2.x `keyfile`; **v3 trick failed** on 2.4.2; device key not available from host `.mdf` alone).
- Partial API recovered (see [`flam-native-lsf.md`](flam-native-lsf.md)); backpack/map/traits appear as Lua modules + `state.*`, not separate host exports.

## Experiments allowed under project constraints

**Allowed**

1. Owner FAH→Flam via official app (option A), if titles exist.
2. Mon Studio linear personal clip (option B).
3. Deepen docs from public Flam.RE / Lunii.QT / community text.
4. Hex/structure on **our** `info`/`key`/indices only ([`custom-pack-sidecars.md`](custom-pack-sidecars.md)).
5. Filename/size/magic contrast vs official tree — **stop** after classification.
6. Watch official pack UI on-device without copying/decrypting files.
7. LIFF encode/decode on our thumbnail.

**Not allowed**

- Decrypt / dump / copy official `main.lsf`, `script/*`, ciphered `info`, or story media.
- Official packs as key oracles for catalog DRM.
- Firmware patching / SWD / jailbreak unless a later Project decision reopens that wall.
- Another classic STUdio→Lunii.QT Tiny Choice variant (v1–v3 exhausted).

## Immediate next milestone

1. **v3-trick closed: FAIL** — canary purged; Emily-only. See [`flam-key-experiment-results.md`](flam-key-experiment-results.md).  
2. Near-term AI pipeline: **do not** assume classic STUdio→Flam **or** personal Flam-native playback. Prefer A/B (FAH / Mon Studio).  
3. Coordinator propose: **Flam.RE author contact** (rank 1) before any SWD; forged canary not worth another device write.

Diagnosis: [`tiny-choice-black-screen.md`](tiny-choice-black-screen.md). Results: [`first-pack-results.md`](first-pack-results.md). LSF: [`flam-native-lsf.md`](flam-native-lsf.md). Keys: [`flam-key-options.md`](flam-key-options.md).
