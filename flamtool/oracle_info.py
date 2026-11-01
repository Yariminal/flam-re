#!/usr/bin/env python
"""oracle_info.py - offline story-key test against an official story.

Usage: oracle_info.py <story_dir> [--mdf PATH]

Tries every mdf/SNU-derived story key+iv candidate on the story's ciphered
`info`. A hit (printable UTF-8, 'script/' marker, or line-4 title repeat)
means the story key is host-derivable and no device key is needed at all.

Note: candidates requiring the device key (keyfile unwrap) cannot be tested
offline; those are covered by the on-device battery.
"""
import os
import sys

from Crypto.Cipher import AES

from flam import Mdf, rev4, cbc_dec, BS


def score(data):
    if not data:
        return 0.0
    good = sum(1 for b in data if b in b"\t\n\r" or 0x20 <= b <= 0x7E)
    return good / len(data)


def main():
    story_dir = sys.argv[1]
    mdf_path = sys.argv[sys.argv.index("--mdf") + 1] if "--mdf" in sys.argv \
        else os.path.join(os.path.dirname(os.path.dirname(story_dir)), ".mdf")
    m = Mdf(mdf_path)
    info = open(os.path.join(story_dir, "info"), "rb").read()
    print(f"info: {len(info)} bytes, mdf fw={m.fw} snu={m.snu_str}")

    Z = bytes(16)
    cands = {
        "B0/B1 (snu blocks)": (m.B0, m.B1),
        "rev4(B0)/rev4(B1)": (rev4(m.B0), rev4(m.B1)),
        "C0/C1 (raw mdf)": (m.C0, m.C1),
        "rev4(C0)/rev4(C1)": (rev4(m.C0), rev4(m.C1)),
        "C0/C1 rev4-sk only": (rev4(m.C0), m.C1),
        "C0/C1 rev4-iv only": (m.C0, rev4(m.C1)),
        "B0/zero-iv": (m.B0, Z),
        "C0/zero-iv": (m.C0, Z),
        "binsnu/zero-iv": (m.snu + bytes(9), Z),
        "B1/B2": (m.B1, m.B2),
        "C1/C2": (m.C1, m.C2),
    }

    hit = False
    for name, (sk, iv) in cands.items():
        for mode, blob in (("cbc", cbc_dec(info[:0x80], sk, iv)),
                           ("ecb-b0", AES.new(sk, AES.MODE_ECB).decrypt(info[:16]))):
            s = score(blob)
            marker = b"script/" in blob or b".lsf" in blob
            if s > 0.95 or marker:
                hit = True
                print(f"HIT [{name}] {mode} score={s:.2f}\n  {blob!r}")
            else:
                print(f"miss [{name}] {mode} score={s:.2f} head={blob[:16]!r}")
    if not hit:
        print("\nno offline hit: story key is NOT mdf/SNU-derived -> wrap unwrap needed")
        print("next: battery.py on device, or device-key recovery (fw RE / wifi MITM)")


if __name__ == "__main__":
    main()
