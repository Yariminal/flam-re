# Flam.RE #1 follow-up — scarlaty / flam-player

Date: 2026-10-27. Source comment: [o-daneel/Flam.RE#1](https://github.com/o-daneel/Flam.RE/issues/1) by **scarlaty** (2026-10-26). Related: [Lunii.QT #75](https://github.com/o-daneel/Lunii.QT/issues/75) (scarlaty carrier steps).

## Public URLs (found)

| Item | URL |
|---|---|
| **flam-player** (GPL-3.0) | https://github.com/scarlaty/flam-player |
| **flam-homebrew** skill | https://github.com/scarlaty/flam-player/tree/main/skills/flam-homebrew |
| Example `.plain.pk` | `stories/histoire-malveillante.plain.pk` in that repo (Lua + LIF; no official catalog) |
| Carrier docs (fw 1.x) | https://github.com/scarlaty/flam-player/blob/main/docs/flam-carrier.md |
| Device format | https://github.com/scarlaty/flam-player/blob/main/docs/flam-device-format.md |
| Related tool | https://github.com/scarlaty/mp3map-tool |

Cloned for host read-only review: `/tmp/flam-re-followup/flam-player` (not copied into this store; no device writes).

## What scarlaty reported (Flam.RE #1)

- Building open-source **flam-player**: PC emulator + Windows launcher; converts personal/Telmi → Flam-native `.plain.pk` and can copy to the user’s own device.
- Same host wrap as our v3 trick for fw 2.x: `key` = `.mdf[0x4E:0x6E]`, AES-128-CBC on `info` / `*.lsf`.
- **fw 1.x validated on a real device**; **fw 2.x not validated yet** — our 2.4.2 garbage-title / 1% stuck load matches their expected fail class.
- Points to `skills/flam-homebrew` for original content (Lua + LVGL, LIF, MP3/mp3map).
- Same non-goals: no catalog decrypt / no shipping device keys.

## Carrier approach (Lunii.QT #75 + flam-player docs)

On **fw 1.x**, classic mdf/SNU keyfile path is coherent inside the app but the firmware still needs a **real device-unwrapped** `key`. Symptom: garbage title + chargement bounce ([#75](https://github.com/o-daneel/Lunii.QT/issues/75)).

**Carrier** (validated by scarlaty on fw **1.15.14**):

1. Take another official story’s on-disk **`key`** (32 B, already device-wrapped).
2. Take that story’s plaintext story materials **`bt`** = AES-128 key (16) ‖ IV (16).
3. Re-cipher personal `info` / scripts with that `bt`; inject the carrier `key` into the new UUID folder.
4. Do **not** copy official prose/audio — only key material + re-cipher of *original* Lua.

`bt` is typically **not** present on-device (only wrapped `key` + ciphered `info`). flam-launcher asks the user to paste/supply `bt` (or a folder/zip that contains it), then verifies by decrypting an official `info` title before any write (`docs/flam-carrier.md`).

For **fw 2.x**, flam-player’s launcher path is the Lunii.QT-style `.mdf` materials (“en test”, not device-validated in-repo). Carrier mode is documented as **1.x-only**.

## Carrier-key viability on **our** fw 2.4.2 (no Emily rip)

Question: can we copy Emily’s 32-byte `key` into a **new UUID** and encrypt **our** dummy LSF under Emily’s story key, without ripping Emily prose/audio?

| Step | Status |
|---|---|
| Copy Emily `key` blob alone (32 B wrap) | Technically possible; not prose/audio. Insufficient by itself. |
| Encrypt dummy `info`/`*.lsf` under Emily’s **story** AES key‖IV | **Requires knowing that story key** (`bt`). |
| Recover Emily story key from on-disk wrap | **No** — needs device AES unwrap. Host sweep ~74k candidates: 0 hits. v3/mdf trick failed on-device. No `bt` sidecar on this unit. |
| flam-player carrier on 2.4.2 | **Not their supported path** (carrier = 1.x). Their 2.x path = mdf wrap, which we already failed. |

**Verdict: still blocked** on fw 2.4.2. Carrier-style “new UUID + original Lua” is exactly what flam-player does on **1.x when `bt` is known**; without an unwrapped story key (or a firmware-accepted wrap), we cannot build a playable personal pack on this unit. No device experiment run for this assessment (constraint: no writes unless owner-approved later).

## Reply posted

Posted on Flam.RE #1 as **Yariminal** (2026-10-27): https://github.com/o-daneel/Flam.RE/issues/1#issuecomment-6434101450

**Solved follow-up** posted as **Yariminal** (2026-11-01): https://github.com/o-daneel/Flam.RE/issues/1#issuecomment-6552957337 — body: [`flam-re-issue1-solved-reply.md`](flam-re-issue1-solved-reply.md) (fw 2.4.2 key wrap inverted; personal packs mint without device key).

Earlier draft retained below for the store.

```text
Thanks @scarlaty — this is extremely helpful.

We can confirm the fw **2.4.2** failure you expected: personal UUID with `key` = `.mdf[0x4E:0x6E]` and AES-128-CBC `info`/`*.lsf` under the SNU-shaped story materials → garbled Bibliothèque title and load stuck at ~1%. Official Emily still fine; canary purged.

We found your public repo: https://github.com/scarlaty/flam-player (and `skills/flam-homebrew` / `.plain.pk`). Same non-goals on our side (personal/original only; no catalog decrypt).

Two questions if you have a moment:
1. Has any **fw 2.x** device ever accepted the mdf wrap path in practice, or have all successful on-device installs been **1.x** (carrier) so far?
2. For a *new* UUID with original Lua (no official assets): does flam-player’s **carrier-key** path (reuse another story’s wrapped `key` + re-cipher under that story’s `bt`) apply only on 1.x, or is there a 2.x variant that doesn’t need ripping carrier content beyond the 32-byte `key` / known `bt`?

Happy to compare notes / retest on 2.4.2 if you want a second data point.
```

## Implications for this project

- flam-player is the strongest public peer project (emulator + launcher + homebrew skill).
- Does **not** currently unblock our 2.4.2 unit: no validated 2.x wrap; carrier needs `bt` we do not have.
- Useful for host-side original Lua / `.plain.pk` authoring **once** a firmware-accepted wrap exists.
- Next asks remain: scarlaty’s answers above; Flam.RE author wrap insight; lawful local FW for offline RE only if owner supplies — still no CFW / no Emily content in store.
