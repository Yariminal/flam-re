# Flam fw 2.x key wrap — full technical documentation

Status: SOLVED for authoring on fw 2.4.2 (2026-11-01). Homebrew packs minted
host-side run on stock firmware. Device key not recovered and not needed.
Closes Flam.RE #1. Explains Lunii.QT #75.

## 1. Device

- Lunii Flam, main fw 2.4.2 (`2.4.2-bc9881da`), SNU `30224020004727`
- Main MCU: ESP32-S3 (native USB). Comm/WiFi MCU: ESP32-MINI-1
- USB: VID:PID `303a:819e` ("Lunii FLAM"), mass storage, ~8 GB (FAT)
- Storage is a µSD on SDIO, Torx 6 access (bypasses USB entirely)
- USB is slow (~4 min / 80 MB) and flaky on some ports; always `sync` +
  clean unmount before power-off
- Device rebuilds `usr/0/library.cache` (decrypted titles) at boot when absent

## 2. Filesystem layout

```
/.mdf                       126 B, device identity + ciphered region (see §3)
/etc/library/list           one lowercase UUID per line (visible stories)
/etc/library/list.hidden    hidden stories
/usr/0/library.cache        title cache, rebuilt at boot (see §6)
/usr/0/<uuid>.save|.prog    per-story runtime state, written on any launch attempt
/str/<uuid>/                story directory
    key                     32 B, wrap input (see §4)
    info                    AES-CBC, story key (see §5)
    main.lsf                AES-CBC Lua entry point
    script/*.lsf            AES-CBC Lua modules
    version                 plain ASCII ("3" official, "1" homebrew)
    img/*.lif               plain LIFF images
    sounds/*.mp3|.mp3map    plain audio + seek tables
/tmp/cable_update_complete  OTA trigger flag
/update-main.enc, update-comm.enc   OTA images (dropped at root, applied at eject)
```

## 3. .mdf byte map (126 B, fw 2.4.2)

```
0x00  01 00                                static
0x02  "2.4.2-bc9881da" + NUL pad           fw version, 48 B field
0x32  "30224020004727" + NUL pad           SNU ascii field, 24 B (SNU24)
0x4A  3a 30 9e 81                          VID/PID LE: 0x303A / 0x819E (Espressif)
0x4E  C0 (16 B)                            \
0x5E  C1 (16 B)                             } C0||C1||C2 = Enc_devkey(SNU24||SNU24)
0x6E  C2 (16 B)                            /
```

The 48-byte region at 0x4E is the device-key encryption of the 48-byte
plaintext `SNU24||SNU24`. It is a built-in known-pair oracle:

```
Enc_devkey(B0) = C0     B0 = (SNU24||SNU24)[0:16]   = "30224020004727\0\0"
Enc_devkey(B1) = C1     B1 = (SNU24||SNU24)[16:32]  = "\0"*8 + "30224020"
Enc_devkey(B2) = C2     B2 = (SNU24||SNU24)[32:48]  = "004727" + "\0"*10
```

## 4. The key wrap (confirmed)

The firmware does NOT decrypt the `key` file. It ENCRYPTS it:

```
story_key = Enc_devkey(key[0:16])        AES-128-ECB, block-independent
story_iv  = Enc_devkey(key[16:32])
```

All `info` / `*.lsf` content is AES-128-CBC under story_key/story_iv,
zero padding (no extra block when already aligned). Media are plain.

### The mint (host-side, any new UUID)

```
key file  = (SNU24||SNU24)[0:32] = B0 || B1 = SNU24 + SNU24[0:8]
          = hexlify(snu) + "\0"*10 + hexlify(snu)[:8]     (32 B)
story_key = C0 = .mdf[0x4E:0x5E]        (known raw bytes)
story_iv  = C1 = .mdf[0x5E:0x6E]        (known raw bytes)
```

Cipher content with C0/C1, write the SNU-derived key file, append the UUID
to `etc/library/list`, delete `usr/0/library.cache`. Done. The device key
never leaves the chip and is never needed.

Constraint: only three Enc_devkey pairs are known (B0..B2 → C0..C2), so the
only usable story key/iv are C0/C1. That is sufficient for all authoring.

## 5. info plaintext format

```
title\n subtitle \n "000000" \n title        (title repeated on line 4)
```

zero-padded to 16. Menu/library title comes from line 1 (block 1, so IV must
be right); line 4 sits outside block 1 (diagnostic for SK-right/IV-wrong).

## 6. library.cache format

```
0x00  u32 count? (01 00 00 00)
0x04  fw string "2.4.2-bc9881da", NUL padded
...   per story: u16le len + uuid ascii + NUL
                 u16le len + "/str/<uuid>" + NUL
                 u16le len + decrypted title (UTF-8) + NUL
                 thumbnail block ("liff" marker + RGB565 data)
```

Host-side decryption readout: titles land here in plaintext after boot.

## 7. Why previous approaches failed

- v3-trick (`key = .mdf[0x4E:0x6E]` + SNU-derived story key): the keyfile is
  fed through Enc_devkey a second time → story key = Enc_devkey(C0), garbage.
  This is also Lunii.QT #75 (fw 1.x same failure class).
- Lunii.QT fw2 branch writes `key = SNU32` and ciphers content with raw
  mdf[0x4E:0x6E]. That is exactly the working model — failures attributed to
  it came from running the fw1 branch or fw < 2.x devices.
- 74k offline KDF candidates vs the Emily oracle: 0 hits because the device
  key is factory-provisioned random, not derived. Offline derivation is dead.

## 8. Battery experiment log (fw 2.4.2, 2026-11-01)

13 stories planted (`ba770000-...-01..12` + control), one boot, verdict read
from menu + library.cache:

| variant | keyfile | story key/iv | result |
|---|---|---|---|
| V01 | C0C1 | B0/B1 | garbage |
| V02 | C0C1 | rev4(B0)/rev4(B1) | garbage |
| V03 | C0C1 | B0/zeros | garbage |
| V04 | SNU32 | C0/C1 | READABLE TITLE — model confirmed |
| V05 | SNU32 | rev4(C0)/rev4(C1) | garbage |
| V06–V12 | misc | misc | garbage |
| CTL | Emily's key | Emily's info verbatim | readable (pipeline control) |

V04 + ECB block-independence ⇒ the transform is AES-128-ECB encryption of
the keyfile under the device key. rev4 = Lunii.QT per-4-byte reversal.

Playback proof: scarlaty/flam-player `casse-briques.plain.pk` (66 files,
device-validated runtime) packed with the mint → runs, wheel works, exit and
relaunch clean. A bare `main()` exits straight back to the menu — on device
the story must be a `Global.load_module()` module (see §10).

## 9. Tooling — /home/yariminal/flam-re/flamtool/

Run with the Lunii.QT venv python (has pycryptodome):
`/home/yariminal/flam-re/luniiqt-tools/venv/bin/python`

| tool | purpose |
|---|---|
| `flam.py` | mdf parse, candidate material, CBC helpers, variant defs |
| `mint.py <root> <uuid> <title> <main.lua> [--more src=dst]` | single authored story |
| `pack.py <root> <story.plain.pk>` | flam-homebrew pack → device, self-keyed |
| `battery.py <root> [--control-from <uuid>]` | hypothesis battery planter |
| `readback.py <root>` | library.cache verdict parser |
| `oracle_info.py <story_dir> [--mdf p]` | offline story-key candidate test |
| `cleanup.py <root> [--prefix ba770000-]` | remove test stories + reset cache |

Standard session: mount (or udisksctl mount -b /dev/sda1) → pack/mint →
`sync` → `udisksctl unmount -b /dev/sda1` → `udisksctl power-off -b /dev/sda`
→ power-cycle device into menu.

## 10. Homebrew content contract (from scarlaty/flam-homebrew, device-validated)

- `.plain.pk` = stored ZIP: `uuid.bin` (16 B), `info.plain`, `version`,
  `main.lua`, `script/<module>_<ver>.lua`, `img/*.lif`, `sounds/*.mp3`
- `main.lua`: firmware calls `setup()`; `Global = require("global")` (global,
  not local); no top-level `require` outside `setup()`
- Game = module: `Global.load_module("name", "1_0_0").create({})`;
  `clean()` destroys everything
- Inputs: wheel left (20) / right (19) via `lv.EVENT_KEY`, click via
  `lv.EVENT_CLICKED`; container added to `document` +
  `lv.group.set_editing(document, true)`
- API whitelist: `lv.*`, `Global.*`, `audio.*`; NO `io`/`os`/`debug`
- Screen 320×240 (play area 320×212), fonts Latin-1 only
- Audio: single track, `audio.load` only when `audio.get_status() == "stop"`
- Images via `Global.load_image("x.lif")` relative to `img/`
- Build/validate: `skills/flam-homebrew/scripts/flam_build.py` + `flam_check.py`
  (zero [ERR] required), simulator `--strict` before device

## 11. Open items

- Device key itself: not recovered, not needed for authoring. Would need
  fw 2.4.2 RE (OTA `update-main.enc` via Luniistore creds → Ghidra Xtensa)
  or ESP32-S3 flash readout. Only required to decrypt official content.
- UUID binding of official keyfiles untested (full Emily-copy control never
  run; light copy listed fine but has no media to play).
- main.lsf constant 16-byte prefix observed on fw1-era dumps
  (`89837DE8...`): not reproduced/needed under the fw2 mint.
- WiFi sync protocol (192.168.4.1:3334 hotspot API) unexplored this session;
  potential route to official-pack plaintext keys if the device wraps
  locally at download.
