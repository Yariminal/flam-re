# Flam library bug — unhide left ghost + corrupt custom pack

Owner report after unhiding **Flam RE Tiny Choice** (`89bb536b-dd44-472e-bfe7-ec7a20a35c4e`): Bibliothèque showed **two** rows; one had a white **“No data”** cover; **both played** the official Emily Jones dinosaur adventure (`c103c95c-a852-4d8f-9c03-82f3814b572d`). Official story content was **not** dumped or decrypted.

## Root cause

**Not** duplicate UUID lines in `etc/library/list`, and **not** a broken `thumbnail.lif` on a healthy pack.

Unhide moved the custom UUID into `str/` and into `list`, but the VFAT write failed mid-flight (`device offline error` / lost async page writes). On remount the kernel remounted **read-only** after `FAT-fs: corrupted directory`. The custom folder appeared as `d---------` with **I/O error** on every open; `fsck.vfat` reported:

> `/STR/89bb536b-…` — Start does point to root directory. Deleting dir.

So the library index listed **two** UUIDs, but only the official pack folder was readable. `usr/0/library.cache` (~19 KB) still held **only** the official entry (title *Emily Jones…* + LIFF). Firmware/UI therefore showed a second selectable row with no usable pack data → **“No data”** thumb; selecting either row effectively played the only loadable story (official).

Host metadata was fine the whole time:

| DB | UUID | Title |
|---|---|---|
| `~/.lunii-qt/third-party.db` | `89bb536b-…` | **Flam RE Tiny Choice** |
| `~/.lunii-qt/official.db` | `c103c95c-…` | **Emily Jones sur la piste des dinosaures disparus** |

## Retry after owner said nothing changed (2026-10-26)

Owner: **same exact behaviour** after the earlier “fix” — two Bibliothèque rows, “No data” cover, both play Emily.

### What was actually on disk (vs what the prior write-up claimed)

| Item | Prior write-up claimed “after fix” | **Reality on remount** |
|---|---|---|
| `etc/library/list` | official only | **official + custom** (74 B, two lines) |
| `etc/library/list.hidden` | custom UUID | **empty** (0 B) |
| `str/` | official only | official OK + custom **`d---------` I/O error** |
| `str.hidden/` | custom pack restored | **empty** |
| Mount | clean rw | remounted **ro** after touching the ghost dir |
| `usr/0/library.cache` | deleted / rebuild | still present ~19 KB; **official UUID only** (no custom string) |
| Host ZIP | kept | still at `~/flam-re/Flam-RE-Tiny-Choice.zip` (49 KB) |

Conclusion: the previous recovery either never stuck through a later unhide/re-import, or the device was never left in the documented end-state from the owner’s POV. Disk still matched the **original ghost** failure mode.

### Official Emily cover assets (filename + size only; no media extract)

Under `str/c103c95c-…/img/` (all magic `liff`):

| File | Size |
|---|---|
| `thumbnail.lif` | 19036 |
| `player_cover.lif` | 21300 |
| `item_Emily.lif` | 12779 |

**Official thumb is present and not missing/corrupt at the path level.** “No data” is explained by the **second (ghost) list entry**, not by Emily’s own LIFF.

### Purge applied this pass

1. Unmount → `fsck.vfat -a` deleted corrupt `/STR/89bb536b-…`, reclaimed ~360 KB orphan clusters, cleared dirty bit.
2. Second `fsck -a` removed leftover orphaned LFN `"89bb536b-…"`. Final `fsck -n` clean aside from harmless boot-sector/backup label offset (65:00/01).
3. Rewrote `etc/library/list` → **official UUID only**; `list.hidden` emptied (0 B).
4. Deleted `usr/0/library.cache` (device rebuilds on next boot). No custom `.save`/`.prog` were present.
5. **Did not** re-import Tiny Choice. ZIP remains on host for later.
6. Volume remounts **rw**; `sync` flushed before handoff.

### After purge (verified)

| Item | State |
|---|---|
| `list` | `c103c95c-a852-4d8f-9c03-82f3814b572d` only |
| `list.hidden` | empty |
| `str/` | official folder only (readable) |
| `str.hidden/` | empty |
| `library.cache` | absent |
| Custom pack on device | **gone** (host ZIP only) |

## Hypotheses — why dual Emily persisted after “fix”

| Hypothesis | Verdict |
|---|---|
| Prior fix never actually left disk in claimed state / was undone | **Supported** — remount still had both UUIDs in `list` + ghost `str/` folder |
| Stale `library.cache` alone | **Weak** — cache never contained custom UUID; UI still walks `list` |
| Custom still in `list` with unreadable folder | **Primary** — exact match to owner symptom |
| Official thumb broken | **Rejected** — `thumbnail.lif` / `player_cover.lif` present, `liff` magic |
| Need power-cycle after USB edits | **Likely contributor** — firmware may keep an in-RAM library until reboot; owner must power-cycle after eject |
| Luniistore Wi‑Fi cache restoring second row | **Unlikely for this pass** — no custom pack left on device; watch if a later sync re-adds anything |

## Can Tiny Choice launch?

**Structure:** classic + Flam sidecars, valid LIFF — host ZIP kept.  
**Owner confirmed** one healthy Emily after purge. **Reimported 2026-10-26** and left **visible** for play-test (see appendix + [`first-pack-results.md`](first-pack-results.md)). On-device Cover → Choice → Ending A|B still needs owner confirmation after safe eject + power-cycle.

## Owner test (done → next is play)

1. ~~Safe eject / power-cycle / confirm one Emily~~ — **done** (owner).
2. **Now:** after reimport — safe eject → power-cycle → expect **two** rows (Emily + Tiny Choice, real covers) → play Tiny Choice graph.

---

## Appendix — Safe reimport procedure (VFAT)

Prior corruption came from flaky VFAT writes during **hide/unhide move storms**. Prefer this path:

1. **Preconditions:** mount `/run/media/yariminal/FLAM` **rw**; `list` = official only; no ghost `str/<uuid>/`; host ZIP ready.
2. **Import** via Lunii.QT `FlamDevice.import_story` (same as GUI File→Import).
3. **Do not hide** for a play-test — leave the pack in `str/` and in `list`.
4. **Delete** `usr/0/library.cache` (or leave absent) so firmware rebuilds on next boot.
5. After every write: **`sync`** (twice is fine).
6. **Remount or reopen** the volume; `ls -ld str/<uuid>/` until readable (`drwx…`, **not** `d---------` / I/O error).
7. Verify `etc/library/list` has the **expected** UUID count; `file`/magic on `img/thumbnail.lif` (`liff`) and a sample `sf/000/*` (MPEG sync after AES `0x200`).
8. **Never leave a ghost dir.** If anything looks wrong → unmount → `fsck.vfat` → fix `list` → only then retry.
9. **Eject safely:** OS eject / `udisksctl unmount` then optionally `udisksctl power-off -b /dev/sdX` — never yank the cable.
10. **Do not touch** official pack content under `str/<official-uuid>/`.
