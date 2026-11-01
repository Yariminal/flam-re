#!/usr/bin/env python
"""cleanup.py - remove flamtool battery/test stories from a mounted Flam.

Usage: cleanup.py <mount_root> [--prefix ba770000-]

Removes str/<uuid>, str.hidden/<uuid>, usr/0/<uuid>.* and the etc/library/list
entries for every UUID with the test prefix, then forces a cache rebuild.
"""
import os
import shutil
import sys

def main():
    root = sys.argv[1]
    prefix = sys.argv[sys.argv.index("--prefix") + 1] if "--prefix" in sys.argv else "ba770000-"

    removed = []
    for d in ("str", "str.hidden"):
        base = os.path.join(root, d)
        if not os.path.isdir(base):
            continue
        for e in os.listdir(base):
            if e.startswith(prefix):
                shutil.rmtree(os.path.join(base, e))
                removed.append(e)
    usr = os.path.join(root, "usr", "0")
    if os.path.isdir(usr):
        for e in os.listdir(usr):
            if e.startswith(prefix):
                os.unlink(os.path.join(usr, e))

    for name in ("list", "list.hidden"):
        lst = os.path.join(root, "etc", "library", name)
        if os.path.isfile(lst):
            keep = [l for l in open(lst) if not l.strip().startswith(prefix)]
            with open(lst, "w") as f:
                f.writelines(keep)

    cache = os.path.join(usr, "library.cache")
    if os.path.isfile(cache):
        os.unlink(cache)
    print(f"removed {len(removed)} test stories, cache reset")


if __name__ == "__main__":
    main()
