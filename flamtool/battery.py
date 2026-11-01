#!/usr/bin/env python
"""battery.py - plant one story per key-wrap hypothesis on a mounted Flam root.

Usage: battery.py <mount_root> [--mdf PATH] [--control-from UUID]

Each variant gets its own UUID (ba770000-...-<n>) and title = "Vnn <short>".
After a device boot, readable title in the menu / library.cache = winning model.
Control story: byte-copy of an official story under a new UUID; validates the
pipeline itself (index, cache rebuild, title source). Must list AND play.
"""
import os
import shutil
import sys

from flam import Mdf, build_variants, variant_uuid, write_story

LIB_LIST = os.path.join("etc", "library", "list")
LIB_CACHE = os.path.join("usr", "0", "library.cache")


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    root = sys.argv[1]
    mdf_path = sys.argv[sys.argv.index("--mdf") + 1] if "--mdf" in sys.argv \
        else os.path.join(root, ".mdf")
    control = sys.argv[sys.argv.index("--control-from") + 1] \
        if "--control-from" in sys.argv else None

    m = Mdf(mdf_path)
    print(f"mdf: fw={m.fw} snu={m.snu_str}")

    # control story: exact copy of an official story, new UUID
    if control:
        src = os.path.join(root, "str", control)
        dst_uuid = "ba770000-0000-4000-8000-0000000000ff"
        dst = os.path.join(root, "str", dst_uuid)
        if os.path.isdir(src):
            if os.path.isdir(dst):
                shutil.rmtree(dst)
            os.makedirs(dst)
            for f in ("key", "info", "main.lsf", "version"):
                shutil.copy2(os.path.join(src, f), dst)
            print(f"control: light copy (key/info/main.lsf/version) of {control} -> {dst_uuid}")
        else:
            print(f"control: {src} not found, skipped")

    planted = []
    for tag, kf, sk, iv, note in build_variants(m):
        uuid = variant_uuid(tag)
        write_story(root, uuid, kf, sk, iv, f"{tag} {note[:24]}")
        planted.append(uuid)
        print(f"{tag} {uuid}  {note}")

    # index: append variants, keep existing entries
    os.makedirs(os.path.join(root, "etc", "library"), exist_ok=True)
    lst = os.path.join(root, LIB_LIST)
    existing = []
    if os.path.isfile(lst):
        existing = [l.strip() for l in open(lst) if l.strip()]
    add = [u for u in planted + (["ba770000-0000-4000-8000-0000000000ff"] if control else [])
           if u not in existing]
    with open(lst, "a") as f:
        for u in add:
            f.write(u + "\n")

    # force title-cache rebuild at next boot
    cache = os.path.join(root, LIB_CACHE)
    if os.path.isfile(cache):
        os.unlink(cache)
        print("library.cache deleted (rebuild at boot)")

    print(f"\n{len(planted)} variants planted. Eject, boot the Flam, open the menu.")
    print("Then remount and run: readback.py <mount_root>")


if __name__ == "__main__":
    main()
