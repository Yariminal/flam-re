#!/usr/bin/env python
"""mint.py - author a firmware-accepted Flam story on fw 2.x (confirmed on 2.4.2).

Model (battery V04 hit + library.cache readback, 2026-11-01):
  fw derives content keys by ENCRYPTING the 32-byte key file under the
  device key (AES-128-ECB, block-independent):
      story_key = Enc_devkey(key[0:16])   story_iv = Enc_devkey(key[16:32])
  .mdf[0x4E:0x7E] = Enc_devkey(SNU24||SNU24) = C0||C1||C2 (known pairs).
  key = (SNU24||SNU24)[0:32]  =>  story_key=C0, story_iv=C1  (known raw bytes).
  Cipher info/*.lsf with AES-128-CBC key=C0 iv=C1, zero padding. Done.
  The device key itself is never needed.

Usage: mint.py <mount_root> <uuid> <title> <main.lua> [--more SRC=DST ...]
"""
import os
import shutil
import sys

from flam import Mdf, cbc_enc, info_plain


def mint(root, uuid, title, lua_path, extra=()):
    m = Mdf(os.path.join(root, ".mdf"))
    keyfile, sk, iv = m.snu32, m.C0, m.C1

    d = os.path.join(root, "str", uuid)
    os.makedirs(os.path.join(d, "script"), exist_ok=True)
    with open(os.path.join(d, "key"), "wb") as f:
        f.write(keyfile)
    with open(os.path.join(d, "info"), "wb") as f:
        f.write(cbc_enc(info_plain(title), sk, iv))
    lsf = cbc_enc(open(lua_path, "rb").read(), sk, iv)
    with open(os.path.join(d, "main.lsf"), "wb") as f:
        f.write(lsf)
    with open(os.path.join(d, "script", "local.lsf"), "wb") as f:
        f.write(lsf)
    with open(os.path.join(d, "version"), "wb") as f:
        f.write(b"3")                      # matches official fw2 pack
    for src, dst in extra:
        t = os.path.join(d, dst)
        os.makedirs(os.path.dirname(t), exist_ok=True)
        shutil.copy2(src, t)               # media stay plain

    lst = os.path.join(root, "etc", "library", "list")
    existing = [l.strip() for l in open(lst)] if os.path.isfile(lst) else []
    if uuid not in existing:
        with open(lst, "a") as f:
            f.write(uuid + "\n")
    cache = os.path.join(root, "usr", "0", "library.cache")
    if os.path.isfile(cache):
        os.unlink(cache)
    print(f"minted {uuid} '{title}' (sk=C0 iv=C1 kf=snu32)")


if __name__ == "__main__":
    extra = []
    if "--more" in sys.argv:
        i = sys.argv.index("--more") + 1
        extra = [a.split("=", 1) for a in sys.argv[i:]]
        sys.argv = sys.argv[:i - 1]
    if len(sys.argv) < 5:
        sys.exit(__doc__)
    mint(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], extra)
