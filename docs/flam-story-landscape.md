# Flam story landscape

Research snapshot for personal authoring / interop. No official pack ripping, no firmware jailbreak path.

## Flam vs classic Lunii (My Fabulous Storyteller)

| | **Flam** | **My Fabulous Storyteller** (Ma Fabrique à Histoires) |
|---|---|---|
| Audience | ~7–12/14 | ~3–8 |
| Form factor | Pocket player, USB-C, Wi‑Fi sync | Larger “storyteller” box; models Lunii‑1/2/3 |
| Screen | 2.8″ **non-touch color**; on only for interaction / UI | No (or minimal) story-interaction screen of Flam’s type |
| Native story model | Scripted interactive adventures (choices, inventory, map, rewards, progress) | Menu/choice graph: hero / place / object-style composition |
| Catalog direction | Flam catalog **does not** go to Storyteller; many Storyteller titles **can** go to Flam | Own catalog; subset labeled “Listen on My Fabulous Storyteller and FLAM” |

Sources: [Lunii — What is FLAM](https://support.lunii.com/hc/fr/articles/11107350447261-Qu-est-ce-que-FLAM-et-comment-fonctionne-t-il), [Why FLAM for 7–11](https://support.lunii.com/hc/en-us/articles/11104111169309-Why-is-FLAM-adequate-for-7-11-years-old), [Transfer Storyteller → Flam](https://support.lunii.com/hc/en-us/articles/10241866592797-Can-I-add-stories-I-ve-bought-for-My-Fabulous-Storyteller-to-FLAM), [Medium UX write-up](https://medium.com/lunii/la-recherche-utilisateur-sur-un-produit-tangible-le-baladeur-interactif-flam-de-lunii-9ca6414db62e).

**Interop rule of thumb:** Flam can *play* classic Lunii-style packs (official “Switch” path; community import via Lunii.QT on Flam firmware **v2.x**). Flam-native packs use a **different** on-device layout and feature set. Flam → Storyteller is not supported for Flam catalog titles.

## How Flam stories work (high level)

### Device / playback surface
- Primary experience is **audio**; screen supports **punctual** UI (choices, menus, inventory, maps).
- Controls: wheel + OK, pause, back, volume, settings; Bluetooth / jack / speaker.
- Progress can persist across sessions (`usr/0/…` save files observed in community FS dumps).
- Transfer: Lunii mobile app over Wi‑Fi; also USB mass-storage style surface used by community tools (Flam USB is reported **very slow**).

### On-device layout (Flam-native)
Community RE documents stories under `/str/<UUID-v4>/`:

```
info          # metadata (title…), story-key ciphered
key           # story AES key+IV wrapped with device key
main.lsf      # entry script (ciphered; Lua-like)
version       # plain revision
img/*.lif     # LIFF images (plain)
img/script/   # UI/menu images
script/*.lsf  # additional scripts (ciphered)
sounds/*.mp3 (+ *.mp3map)  # plain audio
```

Library index: `/etc/library/list` (UUID list). Device meta: `.mdf`. USB VID/PID documented as Espressif-family (`0x303A` / `0x819E` in Lunii.QT).

Sources: [Flam.RE ANALYSIS](https://github.com/o-daneel/Flam.RE/blob/main/ANALYSIS.md), [Flam.RE CIPHERING](https://github.com/o-daneel/Flam.RE/blob/main/CIPHERING.md), [Lunii.QT README (Flam archive types)](https://github.com/o-daneel/Lunii.QT/blob/main/README_EN.md).

### Classic Lunii pack model (what community studios emit)
- Graph of **stage** nodes (image +/or audio) and **action** nodes (transitions / options).
- Device indices: `ni` / `li` / `ri` / `si` + `rf/` bitmaps + `sf/` MP3s.
- Open editor exchange: STUdio archive (`story.json` + `assets/` + `thumbnail.png`).
- Images typically **320×240**; audio MP3 (or converted).

Sources: [STUdio](https://github.com/marian-m12l/studio), [Lunii.RE ANALYSIS](https://github.com/o-daneel/Lunii.RE/blob/main/ANALYSIS.md).

## What “full feature” means on Flam

Marketing + support + product pages consistently describe Flam-native interactivity beyond simple branching audio:

1. **Decisions** — choose-your-own-adventure style branches that change the course of the story  
2. **Backpack / inventory** — collect objects and use them later in the adventure  
3. **Character / personality** — pick or shape traits of heroes / NPCs  
4. **Map / destination navigation** — choose destinations; spatial / chapter navigation  
5. **Rewards & engagement** — unlock rewards; missions / questions; pedagogical side content  
6. **Images / UI** — color LIFF artwork for menus and interaction screens (not continuous video)  
7. **Long-form + resume** — multi-hour books with pause/resume and chapter-like progress (unlike early Storyteller “restart from start” pain points that motivated Flam)

Sources: [Flam product page (FR)](https://lunii.com/fr-fr/products/flam-coque-verte-incluse), [subscription/Flam pitch](https://lunii.com/fr-fr/abonnement-avec-conteuse-flam), [ACFJF Flam PDF](https://www.acfjf.fr/wa_files/FLAM_2C_20le_20baladeur_20interactif_20Lunii_20pour_20les_207-11_20ans.pdf), [support: how Flam works](https://support.lunii.com/hc/fr/articles/11107350447261-Qu-est-ce-que-FLAM-et-comment-fonctionne-t-il).

A **full custom story** for this Project means: authored pack that exercises several of the above **on Flam hardware**, not only linear audio or a classic Lunii menu tree.

## Community tools / studios / open formats

| Tool | Role | Flam relevance |
|---|---|---|
| **[Mon Studio Lunii](https://support.lunii.com/hc/fr/articles/360014414318)** (official mobile) | Record linear audio (≤15 min), icon + title, export to library | [Compatible with Flam](https://support.lunii.com/hc/en-us/articles/14116470821661-Is-My-Lunii-Studio-compatible-with-FLAM) for **recorded** stories — **not** Flam-native interactive mechanics |
| **[STUdio](https://github.com/marian-m12l/studio)** | Create/transfer classic Lunii packs; `story.json` archive | No first-class Flam recognition ([discussion #546](https://github.com/marian-m12l/studio/discussions/546)); packs may reach Flam via other tools |
| **[Story Studio](https://github.com/Hugs11/story-studio)** (Hugs11) | Modern desktop editor → Lunii-compatible ZIP; `.mbah` projects | Targets **Lunii** packs, not Flam-native LSF |
| **[Lunii.QT](https://github.com/o-daneel/Lunii.QT)** | Manage Lunii **and Flam**: import/export/hide, STUdio import, Flam backups | Can import **Lunii/STUdio** stories onto Flam (**firmware v2.x**); Flam-native format still called **unknown** for authoring; personal Flam ZIP/7z backup of `info`/`main.lsf`/… |
| **[Lunii Admin](https://github.com/olup/lunii-admin)** / web | STUdio-format ecosystem | Classic Lunii focus |
| **[Flam.RE](https://github.com/o-daneel/Flam.RE)** | FS layout, ciphering notes, LIFF | Documents structure; Lua interpreter suspected; LIFF reversed |
| **[lif](https://github.com/o-daneel/lif)** | LIFF (QOI-derived) codec | Usable for **images** once scripts/auth are understood |

### Known Flam packaging facts (from community docs)
- **Images (`.lif` / LIFF):** reversed; RGB565/QOI-like; **not encrypted**. Spec: [LIFF_SPEC.md](https://github.com/o-daneel/Flam.RE/blob/main/LIFF_SPEC.md).
- **Audio (`.mp3`):** plain; example ~128 kb/s, 44.1 kHz stereo in Flam.RE notes.
- **Scripts (`.lsf`):** appear Lua-oriented (Flam.RE links Lua / LVGL); **story-ciphered**; public schema **missing**.
- **Auth:** per-story `key` = AES key+IV wrapped by **device** key; backups often device-bound. Do not treat “decrypt official catalog” as an authoring step.

## Gaps vs simple story studios

| Capability | Official Studio | STUdio / Story Studio → Flam | Flam catalog native |
|---|---|---|---|
| Linear custom audio | Yes | Yes (overkill) | Yes |
| Classic branching menus | No | Yes (on Flam via Lunii.QT / fw 2.x) | Emulated when playing Lunii packs |
| Backpack / inventory | No | **No** | Yes |
| Map / destination UI | No | **No** | Yes |
| Character sheets / traits | No | **No** | Yes |
| Rewards / missions / learning hooks | No | **No** | Yes |
| Flam-native LSF authoring | No | **No public tool** | Official pipeline only |
| Documented open pack format for full Flam | — | Classic Lunii only | **Gap** |

**Biggest gap for this Project:** there is a solid path for **classic Lunii-style** custom packs on Flam, and a trivial path for **linear** recordings, but **no public authoring format/API** for Flam-native engagement features (backpack, map, rewards, rich scripted UI). Those live behind ciphered `.lsf` + undocumented Lua/runtime bindings.

## Practical paths (compliant)

1. **Near-term usable custom content:** author with Story Studio / STUdio → import with Lunii.QT on Flam fw **2.x** → get branching + images + audio on device.  
2. **Official personal voice stories:** Mon Studio Lunii → library → Flam sync.  
3. **Full-feature goal:** needs format/runtime discovery from **own** custom experiments and public RE docs—not ripping official packs. Prefer packaging/interop over firmware mods (see `internal/flam-re-plan.md`).

## Open unknowns (device-side)
- Exact Flam firmware generation on the owned unit (1.x vs 2.x matters for Lunii.QT import).  
- Which third-party studio the owner already tried.  
- Whether host OS can mount Flam USB for inspection.  
- Public API surface of the Lua story runtime (inventory, map, save).  
- Stable way to wrap a **new** story `key` that firmware accepts without invasive device-key extraction (see [Lunii.QT #75](https://github.com/o-daneel/Lunii.QT/issues/75) for fw 1.x pitfalls).
