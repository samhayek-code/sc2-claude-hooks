#!/usr/bin/env python3
"""Extract a Tiberian Sun / RA2 'new format' MIX archive (unencrypted).

Layout:
  uint32 flags            # 0x10000=checksum, 0x20000=encrypted
  uint16 fileCount
  uint32 bodySize
  index[fileCount]: { uint32 id; uint32 offset; uint32 size }
  body                    # entry.offset is relative to body start
Entries in a speech mix are raw Westwood .AUD files.
"""
import struct, sys, os

def extract(path, outdir):
    data = open(path, "rb").read()
    flags = struct.unpack_from("<I", data, 0)[0]
    if flags & 0x00020000:
        sys.exit(f"{path}: ENCRYPTED (Blowfish) — needs the RSA/Blowfish path, not handled here")
    has_checksum = bool(flags & 0x00010000)
    # new format: first dword is flags (low word 0); index starts at offset 4
    if (flags & 0x0000FFFF) == 0 and flags != 0 or flags == 0:
        pos = 4
    else:
        # old TD/RA1 format: no flags dword
        pos = 0
    count = struct.unpack_from("<H", data, pos)[0]; pos += 2
    body_size = struct.unpack_from("<I", data, pos)[0]; pos += 4
    index_start = pos
    body_start = index_start + count * 12
    os.makedirs(outdir, exist_ok=True)
    rows = []
    for i in range(count):
        fid, off, size = struct.unpack_from("<IiI", data, index_start + i*12)
        blob = data[body_start + off : body_start + off + size]
        # peek AUD header: uint16 rate, uint32 dataSize, uint32 outSize, u8 flags, u8 type
        rate = ftype = None
        if len(blob) >= 12:
            rate = struct.unpack_from("<H", blob, 0)[0]
            ftype = blob[11]
        name = f"{i:03d}_{fid & 0xFFFFFFFF:08x}.aud"
        open(os.path.join(outdir, name), "wb").write(blob)
        rows.append((i, fid & 0xFFFFFFFF, size, rate, ftype, name))
    return count, body_size, body_start, has_checksum, rows

if __name__ == "__main__":
    path, outdir = sys.argv[1], sys.argv[2]
    count, body_size, body_start, chk, rows = extract(path, outdir)
    print(f"file={path}")
    print(f"  files={count}  bodySize={body_size}  bodyStart={body_start}  checksum={chk}")
    # validate: how many look like real AUD (type 1=WS-ADPCM or 99=IMA-ADPCM, sane rate)
    aud = [r for r in rows if r[4] in (1, 99) and r[3] in (11025, 22050, 44100)]
    print(f"  valid-looking AUD: {len(aud)}/{count}")
    sizes = [r[2] for r in rows]
    print(f"  size range: {min(sizes)}..{max(sizes)} bytes")
    from collections import Counter
    print("  AUD types:", dict(Counter(r[4] for r in rows)))
    print("  rates:", dict(Counter(r[3] for r in rows)))
