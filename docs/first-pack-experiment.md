# First pack experiment (Flam fw 2.4.2)

Concrete run for the owned Flam. **Author only custom content.** Do not copy official packs, decrypt catalog stories, or modify firmware.

**Goal:** Ship a tiny classic Lunii-style branching pack → import with Lunii.QT → play on Flam → USB-inspect **only that new UUID folder**.

**Exit criterion:** Custom 1-choice story plays on Flam; you have a folder tree + file sizes + which files look plain vs ciphered for *your* UUID only.

---

## 0. Preconditions

| Item | Expected |
|---|---|
| Flam firmware | **2.4.2** (confirmed) — Lunii.QT STUdio→Flam import needs **v2.x** |
| Pack | Tiny custom graph: ~2–3 stage nodes + 1 choice (2 endings) |
| Host | PC/Mac/Linux that can run Lunii.QT and mount Flam USB |
| Scope | Inspect **only** the UUID folder Lunii.QT creates for this pack |

Sources: [Lunii.QT README](https://github.com/o-daneel/Lunii.QT/blob/main/README_EN.md), [Flam.RE ANALYSIS](https://github.com/o-daneel/Flam.RE/blob/main/ANALYSIS.md), project [`flam-story-landscape.md`](flam-story-landscape.md).

---

## 1. Install tools

### 1a. Lunii.QT (required for Flam transfer)

1. Download the latest release for your OS: [Lunii.QT releases](https://github.com/o-daneel/Lunii.QT/releases).
2. Install / unzip and launch.
3. Install **FFmpeg** (needed if STUdio assets are not already MP3):
   - **Windows / macOS:** menu **Tools → FFMPEG is missing** → let it download into `~/.lunii-qt` → confirm **Tools → FFMPEG Detected**.
   - **Linux:** `sudo apt-get install ffmpeg` (or distro equivalent), then restart Lunii.QT. If Qt fails to start: `sudo apt install libxcb-cursor0`.

**OS notes (Lunii.QT):**

| OS | Notes |
|---|---|
| **Windows** | Prefer **Windows 11**. Recent builds document **Windows 10 as unsupported**. MSI/portable from Releases. |
| **macOS** | Supported (Big Sur→Tahoe per README; some newer tags say 12+). Unsigned app: Finder → Control-click → **Open** / System Settings → Privacy & Security → **Open Anyway**. |
| **Linux** | Binary or run from source (`python lunii-qt.py`). Need a recent glibc (README: Ubuntu 20.04 too old for some builds; 22.04+). |

Flam USB transfers are **very slow** (~4 min for ~80 MB). A tiny pack should still take noticeable time—do not unplug early.

### 1b. Authoring app (pick one)

**Recommended for this experiment: [Story Studio](https://github.com/Hugs11/story-studio)** (desktop, Win/Linux/macOS Apple Silicon). Easier guided graph → export Lunii ZIP that Lunii.QT imports.

Alternative: **[STUdio](https://github.com/marian-m12l/studio)** (Java; open `http://localhost:8080` after launcher). Same archive shape (`story.json` + `assets/` + `thumbnail.png`). STUdio’s own device transfer targets classic Lunii, **not** Flam—use Lunii.QT for Flam.

Optional outline (JSON + asset list): [`internal/sample-pack/`](../internal/sample-pack/).

---

## 2. Build a tiny custom pack

### Story to build (keep it stupid-small)

```
[Cover]  --OK-->  [Choice prompt]  --wheel+OK-->  [Ending A]
                                      \--------->  [Ending B]
```

- **1 choice**, **2 endings**.
- Placeholder art/audio OK.
- Images: **320×240** PNG/JPEG/BMP ([STUdio docs](https://github.com/marian-m12l/studio)).
- Audio: short MP3 @ **44100 Hz** preferred (avoids long FFmpeg transcodes). WAV/OGG also work if FFmpeg is installed.

### In Story Studio

1. New project → Graph Editor (or Simplified if available for one story).
2. Create screens: Cover, Choice, Ending A, Ending B.
3. Wire Cover → Choice; Choice → two endings.
4. Assign 320×240 images + short MP3s (silence + spoken “A” / “B” is fine).
5. Set pack title e.g. `Flam RE Tiny Choice`; note the generated **UUID**.
6. Generate / export a **Lunii-compatible ZIP** (STUdio-style archive).

### In STUdio (alternative)

1. Pack editor → start from sample or blank.
2. Stage nodes for cover / choice / endings; **action nodes** between them (stage↔action must alternate).
3. Mark cover as **square one** (first / start node).
4. Choice stage: **wheel + ok** enabled; ok transition → action with **two** stage options (endings).
5. Export / save archive ZIP from the library.

### Archive shape (what the ZIP must contain)

```
story.json
thumbnail.png          # optional but nice for library UI
assets/
  <image files>        # referenced by filename from story.json
  <audio files>
```

Exact JSON field names: see [`internal/sample-pack/story.json`](../internal/sample-pack/story.json) and [ArchiveStoryPackReader](https://github.com/marian-m12l/studio/blob/master/core/src/main/java/studio/core/v1/reader/archive/ArchiveStoryPackReader.java). Prefer exporting from Story Studio / STUdio rather than hand-zipping unless you are validating the outline.

**Record now:** pack title, full UUID, ZIP path, ZIP size.

---

## 3. Import to Flam with Lunii.QT

1. Power on Flam; connect **USB-C** to the PC. Wait until the OS shows a mass-storage volume (or Lunii.QT detects it).
2. Open Lunii.QT → refresh device. Status bar should show firmware **2.4.2** (or 2.x).
3. **File → Import** / `Ctrl+I` / drop the ZIP onto the app.
4. Wait for copy to finish (patience—Flam USB is slow).
5. Confirm the new story appears in the list with DB origin **T** (third-party) and note its **UUID** (folder on device uses this UUID; Lunii.QT UI often highlights the last 8 chars).
6. **Optional but recommended before any official Luniistore sync:** right-click → **Hide** the custom story so sync does not delete it ([Lunii.QT hide feature](https://github.com/o-daneel/Lunii.QT/blob/main/README_EN.md)).
7. Eject / safely disconnect; play the story on Flam.

### Playback checklist (note yes/no)

- [ ] Story appears in Flam library
- [ ] Cover image + audio play
- [ ] Choice UI: wheel moves between options; OK selects
- [ ] Ending A and Ending B both reachable
- [ ] Pause / back behavior (anything odd?)
- [ ] Resume after power-off? (optional)

Expect **classic Lunii branching only**—not Flam backpack / map / rewards.

---

## 4. USB-inspect **only the new UUID folder**

1. Reconnect Flam over USB; mount the volume.
2. Open `str/` (stories). Find the folder named with **your pack’s UUID** (dashed UUID-v4).
3. **Copy only that folder** off-device (e.g. Project `artifacts/` or a personal notebook). Do **not** bulk-copy other UUIDs (official catalog).
4. Optionally note one line in `etc/library/list` that matches your UUID—do not dump other titles’ content.

### What to list / measure

For every file under your UUID folder, record:

| Path (relative) | Size (bytes) | Plain or ciphered? | Notes |
|---|---|---|---|
| … | … | … | … |

**How to judge “ciphered” without decrypting:**

- **Likely plain:** readable text (`version`), playable `*.mp3`, images that tools recognize (`*.lif` / bitmaps), classic Lunii indices if present (`ni`, `li`, `ri`, `si`, `rf/`, `sf/`).
- **Likely ciphered / opaque:** high-entropy blobs with no media header; Flam-native names like `main.lsf`, `script/*.lsf`, `info`, `key` if those appear.

**Do not** attempt to unwrap `key` or decrypt official `.lsf`. For this experiment you only care whether *your* imported pack landed as classic indices, Flam-native layout, or a hybrid.

### Expected outcomes (hypothesis)

Lunii.QT may either:

- **A)** Keep a **classic Lunii** layout under the UUID (e.g. `ni` / `li` / `ri` / `si` + `rf/` + `sf/`), or  
- **B)** Wrap into a **Flam-like** tree (`info`, `key`, `main.lsf`, `img/`, `sounds/`, …).

Your tree dump answers which. Compare names only to [Flam.RE ANALYSIS](https://github.com/o-daneel/Flam.RE/blob/main/ANALYSIS.md)—do not open other story folders for content.

### OS mount notes

| OS | Tips |
|---|---|
| **Windows** | Flam appears as a drive letter. Use Explorer or `dir /s`. Eject via tray before unplug. |
| **macOS** | Volume under `/Volumes/…`. Finder copy is fine; use Disk Utility / Finder Eject. |
| **Linux** | Often `/media/$USER/…` or `/run/media/$USER/…`. Prefer file manager or `rsync -a`; `umount` before unplug. USB may need patience between opens. |

---

## 5. What to send back (owner → Project)

Reply with a short report (paste or attach):

1. **Host OS** + Lunii.QT version + authoring tool (Story Studio / STUdio) + versions.
2. **Pack UUID** + title + ZIP size.
3. **Playback results** (checklist above).
4. **Directory tree** of `str/<your-UUID>/` only (file names).
5. **Per-file table:** path, size, plain vs opaque/ciphered guess.
6. **One-line verdict:** classic indices vs Flam-native-looking layout vs mixed.
7. Any errors (import fail, missing FFmpeg, USB timeouts, story won’t play).

Optional: personal ZIP backup of **this** story via Lunii.QT (device-bound; keep private).

---

## 6. Constraints reminder

- No official pack ripping / redistribution.
- No jailbreak, firmware patch, or DRM unwrap for paid catalog.
- Hide custom stories before official sync if you use Luniistore.
- This path exercises **classic** interactivity on Flam fw 2.x—not Flam-native backpack/map APIs.

---

## Sources

- [Lunii.QT](https://github.com/o-daneel/Lunii.QT) / [README_EN](https://github.com/o-daneel/Lunii.QT/blob/main/README_EN.md) — Flam import on fw 2.x, STUdio ZIP, FFmpeg, hide, USB slowness  
- [Story Studio](https://github.com/Hugs11/story-studio) — desktop authoring → Lunii ZIP  
- [STUdio](https://github.com/marian-m12l/studio) — archive format, 320×240, stage/action graph  
- [Flam.RE](https://github.com/o-daneel/Flam.RE) — on-disk Flam-native layout reference (compare structure only)  
- Project: [`flam-story-landscape.md`](flam-story-landscape.md), [`internal/flam-re-plan.md`](../internal/flam-re-plan.md), [`internal/sample-pack/`](../internal/sample-pack/)
