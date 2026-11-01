## Solved on fw 2.4.2 — key wrap direction was inverted

Following up for anyone hitting the same wall (including [@scarlaty](https://github.com/scarlaty) / flam-player).

### Result
Personal / homebrew Flam-native packs **do run on stock fw 2.4.2** when minted host-side. The **device key is not recovered and is not needed** for authoring. This also explains [Lunii.QT #75](https://github.com/o-daneel/Lunii.QT/issues/75).

### Model (confirmed)
Firmware does **not** decrypt the on-disk `key` file. It **encrypts** it:

```
story_key = AES-128-ECB_Enc_devkey(key[0:16])
story_iv  = AES-128-ECB_Enc_devkey(key[16:32])
```

`info` / `*.lsf` are AES-128-CBC under that story_key/iv (zero pad). Media stay plain.

`.mdf[0x4E:0x7E]` is `Enc_devkey(SNU24||SNU24)` as three AES blocks `C0||C1||C2`, so we already know:

| plaintext block | ciphertext |
|---|---|
| B0 = SNU24\|\|"\\0\\0" | C0 = .mdf[0x4E:0x5E] |
| B1 = "\\0"×8 \|\| SNU24[0:8] | C1 = .mdf[0x5E:0x6E] |
| B2 = … | C2 = .mdf[0x6E:0x7E] |

### Mint (any new UUID)
```
key file  = B0 || B1   # = hexlify(SNU) + 10×0x00 + hexlify(SNU)[:8]
story_key = C0
story_iv  = C1
```
Cipher `info`/`*.lsf` with C0/C1, write that `key`, append UUID to `etc/library/list`, delete `usr/0/library.cache`, sync, clean eject, power-cycle.

### Why earlier attempts failed
- **v3-trick** (`key = C0||C1`, cipher with SNU-derived materials): firmware encrypts C0/C1 again → garbage title / ~1% load (our earlier report).
- Offline KDFs vs Emily’s oracle: 0 hits because the device key is factory-random, not derived — and we were assuming the wrong wrap direction anyway.
- Lunii.QT’s fw **2.x** branch (`key = SNU32`, content under raw mdf C0/C1) matches this model; fw **1.x** branch / wrong materials produce #75-class failures.

### Validation
Hypothesis battery on this unit: variant with `key=SNU32` + `SK/IV=C0/C1` → **readable title**; other orientations → garbage. Playback: flam-homebrew `casse-briques.plain.pk` packed this way runs (wheel / exit / relaunch OK) on fw **2.4.2**.

Happy to align with flam-player’s 2.x path if useful. Still not sharing device keys or catalog decryption — authoring only.
