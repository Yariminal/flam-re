"""flam.py - core primitives for Flam fw 2.x key-wrap experiments.

Device model (validated in Flam.RE/CIPHERING.md + .mdf backup):
  .mdf[0x00:0x40]  plain:  fw strings, SNU ascii field (24B @0x32), vid/pid
  .mdf[0x4E:0x7E]  48B ciphered with device key, plaintext believed SNU24||SNU24
  str/<uuid>/key   32B = wrap of story key+iv under device key (exact transform unknown)
  str/<uuid>/info  AES-128-CBC under story key/iv, zero padded
"""
import os
import binascii
from Crypto.Cipher import AES

BS = 16


def rev4(b):
    """Lunii.QT reverse_bytes: per-4-byte-group reversal."""
    return b"".join(b[i:i + 4][::-1] for i in range(0, len(b), 4))


def pad0(b):
    return b + b"\x00" * ((BS - len(b) % BS) % BS)


def cbc_enc(data, key, iv):
    return AES.new(key, AES.MODE_CBC, iv).encrypt(pad0(data))


def cbc_dec(data, key, iv):
    return AES.new(key, AES.MODE_CBC, iv).decrypt(data)


class Mdf:
    def __init__(self, path):
        raw = open(path, "rb").read()
        assert len(raw) == 0x7E, f"mdf len {len(raw):#x}"
        self.raw = raw
        self.fw = raw[0x02:0x32].split(b"\x00")[0].decode()
        self.snu24 = raw[0x32:0x4A]                      # ascii + zero pad
        self.snu_str = self.snu24.split(b"\x00")[0].decode()
        self.snu = binascii.unhexlify(self.snu_str)      # 7 raw bytes
        self.C = raw[0x4E:0x7E]                          # 48 ciphered bytes
        self.C0, self.C1, self.C2 = self.C[0:16], self.C[16:32], self.C[32:48]

    # --- candidate material -------------------------------------------------
    @property
    def snu2(self):
        return self.snu24 * 2                            # believed mdf plaintext

    @property
    def B0(self):
        return self.snu2[0:16]

    @property
    def B1(self):
        return self.snu2[16:32]

    @property
    def B2(self):
        return self.snu2[32:48]

    @property
    def snu32(self):
        """Lunii.QT fw2.x keyfile formula = (SNU24||SNU24)[0:32]."""
        return self.snu2[0:32]

    @property
    def C0C1(self):
        return self.C[0:32]                              # mdf[0x4E:0x6E]

    @property
    def C1C2(self):
        return self.C[16:48]                             # mdf[0x5E:0x7E]


# --- story content ----------------------------------------------------------

LUA_MAIN = b'local function main()\n  print("flamtool")\nend\n\nmain()\n'


def info_plain(title):
    """title in block1 (menu) and repeated on line 4 (outside block1, IV-independent)."""
    return f"{title}\nscript/local.lsf\n000000\n{title}\n".encode()


def version_plain():
    return b"1.0"


# --- variant battery --------------------------------------------------------
# each: (tag, keyfile_fn, sk_fn, iv_fn, note)
def build_variants(m: Mdf):
    Z = bytes(16)
    return [
        ("V01", m.C0C1, m.B0, m.B1, "v3-trick ECB: kf=mdfC0C1, sk/iv=SNU blocks"),
        ("V02", m.C0C1, rev4(m.B0), rev4(m.B1), "V01 + rev4 key/iv"),
        ("V03", m.C0C1, m.B0, Z, "SK=B0, IV=0 (block2+ still valid if SK right)"),
        ("V04", m.snu32, m.C0, m.C1, "Lunii.QT fw2: kf=snu32, sk/iv=raw mdf"),
        ("V05", m.snu32, rev4(m.C0), rev4(m.C1), "V04 + rev4"),
        ("V06", m.C0C1, m.C0, m.C1, "identity: fw uses raw keyfile as sk/iv"),
        ("V07", m.C1C2, m.B1, m.B2, "CBC-48 window: kf=mdfC1C2, sk/iv=B1/B2"),
        ("V08", m.C0C1, m.B0, m.B0, "SK=IV=B0 single-block model"),
        ("V09", m.C0C1, m.snu + bytes(9), Z, "SK=binary-snu padded, IV=0"),
        ("V10", bytes(32), m.B0, m.B1, "zero keyfile probe (no-key behavior)"),
        ("V11", m.C0C1, m.B0, rev4(m.B1), "SK=B0, IV=rev4(B1)"),
        ("V12", m.C0C1, rev4(m.B0), m.B1, "SK=rev4(B0), IV=B1"),
    ]


def variant_uuid(tag):
    return f"ba770000-0000-4000-8000-{int(tag[1:]):012d}"


def write_story(root, uuid, keyfile, sk, iv, title):
    d = os.path.join(root, "str", uuid)
    os.makedirs(os.path.join(d, "script"), exist_ok=True)
    with open(os.path.join(d, "key"), "wb") as f:
        f.write(keyfile)
    with open(os.path.join(d, "info"), "wb") as f:
        f.write(cbc_enc(info_plain(title), sk, iv))
    lsf = cbc_enc(LUA_MAIN, sk, iv)
    with open(os.path.join(d, "main.lsf"), "wb") as f:
        f.write(lsf)
    with open(os.path.join(d, "script", "local.lsf"), "wb") as f:
        f.write(lsf)
    with open(os.path.join(d, "version"), "wb") as f:
        f.write(version_plain())
    return d
