#!/usr/bin/env python3
"""Recover canonical filenames: map mix index IDs -> LMD names by reversing
the Westwood TS/RA2 filename hash. Brute-tests several candidate algorithms
against the known (id, name) pairs and reports which maps all of them."""
import struct, re, zlib, sys
from collections import Counter

def read_index(path):
    data = open(path, "rb").read()
    flags = struct.unpack_from("<I", data, 0)[0]
    pos = 4 if (flags & 0xFFFF) == 0 else 0
    count = struct.unpack_from("<H", data, pos)[0]; pos += 2
    body_size = struct.unpack_from("<I", data, pos)[0]; pos += 4
    ids = [struct.unpack_from("<IiI", data, pos + i*12)[0] for i in range(count)]
    body_start = pos + count*12
    # find LMD, pull names
    names = []
    for i in range(count):
        fid, off, size = struct.unpack_from("<IiI", data, pos + i*12)
        blob = data[body_start+off: body_start+off+size]
        if blob[:3] == b"XCC":
            names = [m.decode() for m in re.findall(rb"[0-9A-Za-z._-]{5,}\.aud", blob, re.I)]
    return [x & 0xFFFFFFFF for x in ids], names

# ---- candidate hash algorithms ----
def classic(name):  # TD/RA1 rol-add
    name = name.upper(); i = 0; id = 0; l = len(name)
    while i < l:
        a = 0
        for _ in range(4):
            a >>= 8
            if i < l: a = (a + (ord(name[i]) << 24)) & 0xFFFFFFFF
            i += 1
        id = ((((id << 1) | (id >> 31)) & 0xFFFFFFFF) + a) & 0xFFFFFFFF
    return id

def crc_xcc(name):  # CRC32 with XCC count-byte + repeat padding
    name = name.upper(); n = len(name); b = bytearray(name, "ascii")
    if n & 3:
        b.append(n & 3)
        first = b[n & ~3]
        while len(b) & 3: b.append(first)
    return zlib.crc32(bytes(b)) & 0xFFFFFFFF

def crc_zeropad(name):
    b = bytearray(name.upper(), "ascii")
    while len(b) % 4: b.append(0)
    return zlib.crc32(bytes(b)) & 0xFFFFFFFF

def crc_plain(name):
    return zlib.crc32(name.upper().encode("ascii")) & 0xFFFFFFFF

CANDS = {"classic": classic, "crc_xcc": crc_xcc, "crc_zeropad": crc_zeropad, "crc_plain": crc_plain}

for path in sys.argv[1:]:
    ids, names = read_index(path)
    idset = set(ids)
    print(f"\n{path}: {len(ids)} ids, {len(names)} LMD names")
    print("  faction split (i/n):", dict(Counter(nm[3].lower() for nm in names if len(nm) > 3 and nm[2] == '-')))
    for cname, fn in CANDS.items():
        hits = sum(1 for nm in names if fn(nm) in idset)
        print(f"  {cname:12s}: {hits}/{len(names)} names hash to a real id")
