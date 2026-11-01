#!/usr/bin/env python
"""pack.py - install a flam-homebrew .plain.pk on a fw 2.x Flam, self-keyed.

Usage: pack.py <mount_root> <story.plain.pk>

Ciphering model (confirmed 2.4.2): story key/iv = Enc_devkey(key blocks);
key = (SNU24||SNU24)[0:32] forces key=.mdf[0x4E:0x5E], iv=.mdf[0x5E:0x6E].
All .lua are ciphered to .lsf, info.plain to info, media copied plain.
"""
import os
import sys
import zipfile
from uuid import UUID

from flam import Mdf, cbc_enc


def pack(root, pk_path):
    m = Mdf(os.path.join(root, ".mdf"))
    keyfile, sk, iv = m.snu32, m.C0, m.C1

    with zipfile.ZipFile(pk_path) as z:
        names = [n for n in z.namelist() if not n.endswith("/")]
        uuid = str(UUID(bytes=z.read("uuid.bin")))
        dest = os.path.join(root, "str", uuid)
        if os.path.isdir(dest):
            sys.exit(f"{uuid} already on device - remove it first")
        for n in names:
            base = os.path.basename(n)
            if base in ("uuid.bin",):
                continue
            data = z.read(n)
            if base == "info.plain":
                out, data = "info", cbc_enc(data, sk, iv)
            elif n.endswith(".lua"):
                out, data = n[:-4] + ".lsf", cbc_enc(data, sk, iv)
            else:
                out = n                                # version, lif, mp3, mp3map: plain
            t = os.path.join(dest, out)
            os.makedirs(os.path.dirname(t), exist_ok=True)
            with open(t, "wb") as f:
                f.write(data)
        with open(os.path.join(dest, "key"), "wb") as f:
            f.write(keyfile)

    lst = os.path.join(root, "etc", "library", "list")
    existing = [l.strip() for l in open(lst)] if os.path.isfile(lst) else []
    if uuid not in existing:
        with open(lst, "a") as f:
            f.write(uuid + "\n")
    cache = os.path.join(root, "usr", "0", "library.cache")
    if os.path.isfile(cache):
        os.unlink(cache)
    print(f"packed {os.path.basename(pk_path)} -> {uuid} ({len(names)} files)")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    pack(sys.argv[1], sys.argv[2])
