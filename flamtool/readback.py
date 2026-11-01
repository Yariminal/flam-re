#!/usr/bin/env python
"""readback.py - score battery results after a device boot.

Usage: readback.py <mount_root>

Reads usr/0/library.cache (decrypted titles written by the firmware) and
reports, per battery UUID, the printable strings found. A readable
"Vnn ..." title identifies the winning hypothesis. Partial structure
(line-4 marker readable, block1 garbage) means SK right / IV wrong.
"""
import os
import re
import sys

from flam import build_variants, variant_uuid, Mdf

PRINTABLE = re.compile(rb"[\x20-\x7e]{4,}")


def strings_at(buf, anchor):
    """printable runs with offsets, anchored search helper"""
    out = []
    for m in PRINTABLE.finditer(buf):
        out.append((m.start(), m.group().decode(errors="replace")))
    return out


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    root = sys.argv[1]
    cache_path = os.path.join(root, "usr", "0", "library.cache")
    if not os.path.isfile(cache_path):
        sys.exit("library.cache not found - did the device boot and rebuild it?")
    cache = open(cache_path, "rb").read()
    print(f"library.cache: {len(cache)} bytes")

    m = Mdf(os.path.join(root, ".mdf"))
    variants = [tag for tag, *_ in build_variants(m)]
    uuids = {tag: variant_uuid(tag) for tag in variants}
    uuids["CTL"] = "ba770000-0000-4000-8000-0000000000ff"

    # locate each uuid in the cache, dump nearby strings
    for tag, uuid in uuids.items():
        ub = uuid.encode()
        # cache may store uuids raw-ascii or binary; try both
        idxs = []
        for needle in (ub, ub.replace(b"-", b""), bytes.fromhex(uuid.replace("-", ""))):
            i = cache.find(needle)
            if i >= 0:
                idxs.append(i)
        if not idxs:
            print(f"{tag}: uuid NOT in cache (not listed or scan failed)")
            continue
        i = idxs[0]
        window = cache[i:i + 0x120]
        strs = strings_at(window, ub)
        mark = [s for _, s in strs if s.startswith(tag) or tag in s]
        print(f"{tag} @{i:#x}: " + ("HIT " + repr(mark[0]) if mark else f"strings={strs[:4]}"))

    # global dump of title-looking runs for manual review
    print("\n--- all printable runs in cache (>=6 chars) ---")
    for off, s in strings_at(cache, b""):
        if len(s) >= 6:
            print(f"  {off:#06x}  {s}")


if __name__ == "__main__":
    main()
