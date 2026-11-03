# Flam Lunii RE — project context

## Goal
Understand how Flam (Lunii) packs interactive learning stories, then build a personal library and an AI authoring workflow that uses the device’s full feature set (decisions, backpack, media, engagement mechanics)—without piracy or firmware mods.

## In scope
- Reverse-engineer / document the **original story packaging and playback mechanism** (format, assets, branching, backpack, images, device-facing features)
- Produce at least one **full working custom story** that exercises unique hardware/software features
- Design a **personal library** workflow and an **AI pipeline** to generate complete interactive stories

## Out of scope
- Copying or redistributing copyrighted Flam/Lunii story content
- Jailbreaking the device, hardware exploits, or flashing CFW (confirmed 2026-10-26 — not pursued)
- Firmware modification, DRM circumvention for official library theft, or anything that undercuts Flam’s paid catalog
- Helping Flam makers lose money; intent is to unlock **this owned device** for personal use

## Principles
- Prefer official or community-documented authoring paths over invasive RE
- Prefer format-compatible packaging over device modification
- Keep originals and custom content clearly separated; never ship ripped official assets
- Document findings for reuse in the AI workflow

## Progress (owner-confirmed 2026-11-01)

Steps **1–4 done** on fw 2.4.2:

1. Flam mounted path exercised (`/run/media/yariminal/FLAM`)
2. Homebrew **casse-briques** packed and played
3. Original hello minted
4. Battery experiment cleaned

Key wrap: [`fw2-key-wrap.md`](fw2-key-wrap.md). Authoring loop: [`author-mint-play.md`](author-mint-play.md).

## Open questions
- ~~Does the staged **v3-trick** personal UUID decrypt on-device?~~ **No** — failed on 2.4.2 ([`flam-key-experiment-results.md`](flam-key-experiment-results.md)).
- ~~Can a finite host sweep of SNU/`.mdf`/KDF/byte-order candidates recover device AES or unwrap Emily `info`?~~ **No** — ~74k candidates, 0 hits ([`flam-key-candidate-sweep.md`](flam-key-candidate-sweep.md)).
- ~~Does REA + Lunii.QT/Flam.RE host sources recover a concrete device-key unwrap?~~ **No** — MISS; no local FW blob for Ghidra ([`rea-flam-findings.md`](rea-flam-findings.md)).
- ~~Can Emily **carrier-key** (copy wrap + re-cipher under Emily story key) unlock a new UUID on 2.4.2 without ripping content?~~ **No** — story key (`bt`) unknown; still blocked ([`flam-re-issue1-followup.md`](flam-re-issue1-followup.md)).
- ~~Has any **fw 2.x** device ever accepted mdf-wrap / personal mint?~~ **Yes** — this unit; host mint with SNU32 key + C0/C1 CBC ([`fw2-key-wrap.md`](fw2-key-wrap.md)).
- ~~Minimal self-contained Lua hello once wrap exists?~~ **Yes** — original hello minted (step 3); playable stories need `Global.load_module` ([`fw2-key-wrap.md`](fw2-key-wrap.md) §10).
- Do choice / backpack / map modules from flam-homebrew runtime work end-to-end in an **original** pack on this device? (scaffold: [`ai-flam-pipeline.md`](ai-flam-pipeline.md))
- Do any **owner FAH** titles play on this Flam via the official Lunii app (control for vendor classic packaging)?
- Which third-party studio the owner originally found (optional)
- Device key recovery / official decrypt: still optional, not needed for authoring (OTA RE or flash readout only if owner wants catalog analysis)

## Next milestone
**Kipodi bike** device-proven (full interactive: chapters + backpack + Box Breaker). Public example + authoring guide published under `stories/kipodi-learns-to-ride-a-bike/` and [`authoring-full-story.md`](authoring-full-story.md). Lost Button remains the short feature demo. Out of scope remains CFW and catalog rip.


## Owner toolkit
- Flam firmware **2.4.2**
- Host: Linux; Flam USB mount `/run/media/yariminal/FLAM` (VID/PID `303a:819e`, serial `30224020004727`)
- Lunii.QT, FFmpeg, Story Studio installed
- Story Studio English on [Yariminal/story-studio](https://github.com/Yariminal/story-studio) `main`
- Peer ref: [scarlaty/flam-player](https://github.com/scarlaty/flam-player) + [`skills/flam-homebrew`](https://github.com/scarlaty/flam-player/tree/main/skills/flam-homebrew)

## Breakthrough — fw 2.x key wrap (2026-11-01)

**SOLVED for authoring** without recovering the device key. See [`docs/fw2-key-wrap.md`](fw2-key-wrap.md).

- Firmware **encrypts** (AES-128-ECB) the on-disk `key` file under the device key → `story_key` / `story_iv`
- Mint: `key` = SNU32 (`SNU24||SNU24[0:8]`); cipher `info`/`*.lsf` with `.mdf[0x4E:0x6E]` (= C0||C1)
- Explains our v3-trick fail and Lunii.QT #75 (wrong direction / wrong materials)
- Device-validated: homebrew `casse-briques` runs on 2.4.2; tooling under `~/flam-re/flamtool/` on the laptop
- Repeatable host workflow: [`author-mint-play.md`](author-mint-play.md); AI scaffold: [`ai-flam-pipeline.md`](ai-flam-pipeline.md)

## Findings so far
- **2026-11-01** — **Lost Button** first AI-assisted original homebrew: built (`flam_check` 0 ERR), fw2-minted via `pack.py` to UUID `6c35f0b4-1319-b1c5-f81b-1cc39db96de9`, synced + clean eject. Exercises list-choice + session backpack + title-card. Host pack: `~/flam-re/stories/lost-button/_out/lost-button.plain.pk`. Doc: [`lost-button.md`](lost-button.md); sources: `internal/lost-button/`. **Owner play-test OK** (readable title, full path).
- **2026-11-01** — Owner confirmed steps 1–4 (mount, casse-briques, original hello, battery cleanup). Next: AI pipeline + richer stories.

- **2026-11-01** — **Flam.RE #1 solved reply posted** as Yariminal: https://github.com/o-daneel/Flam.RE/issues/1#issuecomment-6552957337 — fw 2.4.2 key wrap inverted; personal mint without device key. Body: [`flam-re-issue1-solved-reply.md`](flam-re-issue1-solved-reply.md). Also noted in [`flam-re-issue1-followup.md`](flam-re-issue1-followup.md).
- **2026-10-27** — **Flam.RE #1 / scarlaty follow-up:** Public [flam-player](https://github.com/scarlaty/flam-player) (GPL-3) + `skills/flam-homebrew` / `.plain.pk`. fw 1.x device-OK; fw 2.x not validated (matches our 2.4.2 fail). **Carrier-key** needs official story `bt` (plaintext AES‖IV) + wrapped `key`; without `bt`, Emily-key copy into new UUID **still blocked** on 2.4.2 (no content rip, no device write). Reply posted as Yariminal. Doc: [`flam-re-issue1-followup.md`](flam-re-issue1-followup.md).
- **2026-10-26** — **REA Flam key path MISS:** `rea-agents@6.8.0` + Ghidra **12.1.4** installed; analyzed Lunii.QT `device_flam.py` / Flam.RE crypto (redacted) / `.mdf`+Emily oracle. No local `update-*.enc`. Offline unwrap **0** hits. Docs: [`rea-flam-setup.md`](rea-flam-setup.md), [`rea-flam-findings.md`](rea-flam-findings.md).
- **2026-10-26** — **Host key/wrap sweep MISS:** ~74 129 candidates (SNU/mdf/KDF/byte-order/fw1↔fw2/prior fails/AES-256/alt modes) vs Emily `key`/`info` + `.mdf` PT/CT — **0** device-key or title decrypt hits. No canary deployed. Doc: [`flam-key-candidate-sweep.md`](flam-key-candidate-sweep.md).
- **2026-10-26** — Opened Flam.RE question: [o-daneel/Flam.RE#1](https://github.com/o-daneel/Flam.RE/issues/1) — personal Flam-native `key` wrap on fw 2.x (draft: [`flam-re-github-question.md`](flam-re-github-question.md)).
- **2026-10-26** — **v3-trick FAILED** on fw 2.4.2: Bibliothèque garbled title `o:xZ'_2aKaMD(`, load stuck at **1%** (UUID `dc0bf8f5-…`). Emily OK. Canary **purged** (`str/` + list + saves + `library.cache`); Emily-only verified. Personal native packs still blocked. Docs: [`flam-key-experiment-results.md`](flam-key-experiment-results.md), [`flam-key-options.md`](flam-key-options.md).
- **2026-10-26** — **Key options:** Chose Flam.RE **v3 trick** over forged-key canary / SWD. Staged then play-tested (fail above). Host staging retained: `internal/flam-native-hello/`.
- **2026-10-26** — **Flam-native LSF pass:** Emily tree verified (ciphered `info`/`key`/`*.lsf`; plain LIFF/MP3/mp3map/`version`). Host `.mdf` “story” bytes **do not** decrypt Emily scripts. Partial Lua API from public Flam.RE. Docs: [`flam-native-lsf.md`](flam-native-lsf.md), [`internal/flam-native-skeleton-plan.md`](../internal/flam-native-skeleton-plan.md).
- **2026-10-26** — Owner retested **v3**: **load failure** (“loading the story” then fail — never reaches title). On-disk pack readable; `debug_plain` left plaintext `li`/`ri`/`si`/`rf`/`sf` while fw classic path expects cipher (v2 ciphered at least opened). **Classic STUdio→Lunii.QT path blocked** on this 2.4.2 unit after v1–v3. Tiny Choice **purged**; Bibliothèque Emily-only verified post-`sync`/remount. ZIP/sources kept on host. Docs: [`tiny-choice-black-screen.md`](tiny-choice-black-screen.md), [`first-pack-results.md`](first-pack-results.md), [`flam-native-path.md`](flam-native-path.md).
- **2026-10-26** — Owner retested **v2**: same black screen, **no audio**. Dark-cover/OK hypothesis **ruled out**. Host AES round-trip of our `rf`/`sf` **pass**; official Emily = **Flam-native only**. Matches open [Lunii.QT #61](https://github.com/o-daneel/Lunii.QT/issues/61).
- **2026-10-26** — Owner: Tiny Choice opens (title) then **black screen / no choices** (v1).
- **2026-10-26** — Safe reimport left visible; later library bug after unhide (VFAT ghost) fixed — [`flam-library-bug.md`](flam-library-bug.md).
- **2026-10-26** — First custom pack: classic indices + Flam sidecars via Lunii.QT — **not** Flam-native. Sidecars: [`custom-pack-sidecars.md`](custom-pack-sidecars.md). ZIP: `media/Flam-RE-Tiny-Choice.zip`.
- **2026-10-26** — USB inspect: fw **2.4.2**; official UUID Flam-native (names/magic only). [`flam-usb-inspect.md`](flam-usb-inspect.md).
- **2026-10-22** — Flam ≠ classic Storyteller; full features need Flam-native LSF (not public). Landscape: [`flam-story-landscape.md`](flam-story-landscape.md). Usable personal paths now: **(A)** FAH via official app, **(B)** Mon Studio linear, **(C)** Flam-native research — **not** classic STUdio→Lunii.QT on this unit.
- **2026-10-23** — Story Studio English on [Yariminal/story-studio](https://github.com/Yariminal/story-studio) `main`; guide: [`story-studio-english.md`](story-studio-english.md).
