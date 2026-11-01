# REA Flam findings — device `key` wrap (fw 2.4.2)

Date: 2026-10-26. Setup: [`rea-flam-setup.md`](rea-flam-setup.md). Constraints: no CFW flash, no SWD/HCI exploits, no Emily content dumps; API/crypto structure OK.

## Verdict

**MISS** — no concrete host-derivable device-key unwrap recovered. Offline Emily `key`/`info` oracle: **0** title-like hits. No `internal/flam-device-key-method.md` (HIT-only). No canary written.

## Inventory (on disk)

| Target | Path | Usable for wrap RE? |
|---|---|---|
| Lunii.QT source | `~/flam-re/luniiqt-tools/Lunii.QT` | **Yes** — host forge / fw1↔fw2 assignment (not real device key) |
| Flam.RE docs + tools | `~/flam-re/Flam.RE` | **Partial** — CIPHERING model; `crypto_tool.py` keys **redacted** |
| Packaged Lunii.QT ELF | `~/.local/opt/lunii-qt/lunii-qt` (~89 MB) | Host app only; same Python crypto model when unpacked |
| Device `.mdf` | `/run/media/yariminal/FLAM/.mdf` + `~/.lunii-qt/30224020004727.v2.4.2.mdf` | Layout + known PT/CT; **not** enough to recover AES key |
| Emily `key` / `info` | `str/c103c95c-…/` | Oracle only (structure / title-like check) |
| `update-*.enc` / FW dump | — | **Absent** (not on SD; no owner backup found; not downloaded) |
| Flam.RE Ghidra `.gar` | Documented in ANALYSIS, **not** in public clone | Missing |

REA `import-reference-source` hashed Lunii.QT `pkg/api` and Flam.RE `tools/python`. Entropy on Emily `key` (32 B) and `.mdf` (126 B) observed; no firmware image for Ghidra/Hopper.

## Algorithm (from host sources + Flam.RE — structure)

### On-disk model (confirmed)

- `key` (32 B) = AES-CBC under **device key+IV** of `story_key[16] ‖ story_iv[16]`.
- `info` / `*.lsf` = AES-CBC under **story** key+IV (zero-pad in Flam.RE tooling).
- `.mdf[0x4E:]` (48 B) = AES-CBC under device key of `SNU_ascii‖pad` ×2 (known plaintext).

### Lunii.QT `device_flam.py` fw1 vs fw2 (host import path)

| FW | Written `key` / `keyfile` | Host “story” materials |
|---|---|---|
| **1.x** | `mdf[0x4E:0x6E]` (device-wrapped blob from metadata) | `hexlify(SNU)‖\\x00\\x00` / `8×\\x00‖hexlify(SNU)[:8]` |
| **2.x** (incl. **2.4.2**) | **Forge:** `hexlify(SNU)‖10×\\x00‖hexlify(SNU)[:8]` | Raw `mdf[0x4E:0x6E]` treated as key/IV (**ciphertext**, not recovered key) |

Imports copy that `keyfile` onto packs. That is **not** a derivation of the eFuse/device secret; it is a host-side forge for classic (and attempted native) packaging. On this unit Emily `key` ≠ forge and ≠ `mdf[0x4E:0x6E]` (sha256 prefixes differ).

### Flam.RE

- CIPHERING: device key wraps `key`; story key ciphers `info`/LSF; v3 trick = reuse `.mdf` CT as wrap of known SNU-shaped story materials.
- `crypto_tool.py`: writes opaque `key_file` + AES-CBC with redacted `raw_dev_*` — author held a real wrap; **not published**.
- README reverse state still lists memory dump TODO / SWD aborted; public tree has **no** FW binary or Ghidra archive despite ANALYSIS text.

### Inputs that do **not** yield the device key (this unit)

SNU, `.mdf` fields, VID:PID, fw string, Lunii.QT forge, mdf CT-as-key, finite KDF/hash sweeps ([`flam-key-candidate-sweep.md`](flam-key-candidate-sweep.md)), reverse_bytes / half swaps.

**Likely real inputs (not recovered here):** MCU-bound secret (eFuse / NVS / flash — Flam.RE path implies invasive dump). Host math from SD alone does not expose it.

## Offline verify (Emily oracle)

Re-ran AES-128-CBC unwrap recipes from Lunii.QT / prior fails against owned Emily `key` then `info` (title-like printable heuristic; no title text stored):

| Family | Result |
|---|---|
| Forge / mdf-CT / SNU-pad as device key+IV → unwrap `key` → decrypt `info` | MISS |
| Direct story decrypt of `info` with SNU / mdf / forge pairs | MISS |
| Forge/mdf recipes as device key vs `.mdf` known PT | MISS |

Aligns with v3-trick fail ([`flam-key-experiment-results.md`](flam-key-experiment-results.md)) and ~74k candidate sweep MISS.

## Limits

1. **No Flam firmware blob** on disk → REA+Ghidra cannot decompile wrap/unwrap in MCU code.
2. REA does not invent crypto from `.mdf`/Python; it inventories and (with a binary) decompiles. Python path is already fully readable without REA.
3. Official `update-*.enc` download needs Lunii account auth (`firmware.py`); not fetched (no credentials in this run; avoid pirated FW).
4. Hopper/IDA/binwalk not wired; optional for future FW work.

## Next step (ranked, still no device write)

1. Wait / follow [Flam.RE #1](https://github.com/o-daneel/Flam.RE/issues/1) / author contact for how redacted `crypto_tool` got a valid wrap.
2. If owner supplies a **lawful** local `update-main.enc` (or decrypted FW from their backup), point REA+Ghidra at it for wrap/eFuse code — still no flash.
3. Official FAH / Mon Studio personal paths while wall stands.
4. SWD/memory dump only if owner explicitly asks (project out of scope otherwise).

Evidence: `internal/rea-flam/` (doctor + import/entropy JSON). No raw device keys in this doc.
