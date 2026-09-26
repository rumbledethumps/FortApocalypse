#!/usr/bin/env python3
"""Pack the level maps and the navitron images for UNPACK in fort1.s.

usage: levels.py OUTPUT.s LEVEL1 LEVEL2 NAVITRON1 NAVITRON2

The maps are the Atari LEVEL files. The navitron images are 40 rows of
108 pixels: . background, R PF0, W PF1, B PF2.
"""
import sys


def screen_code(ch):
    c = ord(ch)
    if c < 0x20:
        return c + 0x40
    if c < 0x60:
        return c - 0x20
    return c


# The run-length codes, CHR1 and CHR2 in fort1.s
MAP_RUNS = [screen_code(c) for c in " a./01*+,-#'?st"] + \
    [0x41, 0x44, 0x48, 0x58, 0x59, 0x5A, 0xD8, 0xC7]
SCAN_RUNS = [0x00, 0x55, 0xAA, 0xFF]

PIXELS = {'.': 0, 'R': 1, 'W': 2, 'B': 3}


def pack(data, runs):
    """A code in runs is followed by a count, and any other byte is itself."""
    out = bytearray()
    i = 0
    while i < len(data):
        b = data[i]
        if b in runs:
            n = 1
            while i + n < len(data) and data[i + n] == b and n < 255:
                n += 1
            out += bytes([b, n])
            i += n
        else:
            out.append(b)
            i += 1
    return bytes(out)


def unpack(data, runs, size):
    out = bytearray()
    i = 0
    while len(out) < size:
        b = data[i]
        i += 1
        n = 1
        if b in runs:
            n = data[i] or 256
            i += 1
        out += bytes([b]) * n
    return bytes(out)


def level_map(path):
    """40 rows of 256 bytes, after the 11-byte header of a LEVEL file."""
    data = open(path, 'rb').read()[11:11 + 0x2800]
    if len(data) != 0x2800:
        sys.exit('%s: too short for a level' % path)
    return data


def navitron(path):
    """40 rows of 40 bytes of 2-bit pixels. Bytes 27-39 of a row are zero;
    M.NEW.LEVEL copies bytes 0-12 there."""
    rows = [r for r in open(path).read().split('\n') if r]
    if len(rows) != 40 or any(len(r) != 108 for r in rows):
        sys.exit('%s: not 40 rows of 108 pixels' % path)
    out = bytearray()
    for row in rows:
        px = [PIXELS[c] for c in row]
        for b in range(0, 108, 4):
            out.append(px[b] << 6 | px[b + 1] << 4 | px[b + 2] << 2 | px[b + 3])
        out += bytes(13)
    return bytes(out)


def emit(out, label, data):
    out.append('%s:' % label)
    for i in range(0, len(data), 16):
        out.append('        .byte ' + ','.join('$%02X' % b for b in data[i:i + 16]))


def main():
    if len(sys.argv) != 6:
        sys.exit(__doc__)
    output, map1, map2, scan1, scan2 = sys.argv[1:]
    out = ['; Packed from the level maps and navitron images by levels.py', '',
           '.export PACKED_MAP_1, PACKED_MAP_2, PACKED_SCAN_1, PACKED_SCAN_2', '',
           '.segment "LEVELS"', '']
    for label, data, runs in (('PACKED_MAP_1', level_map(map1), MAP_RUNS),
                              ('PACKED_MAP_2', level_map(map2), MAP_RUNS),
                              ('PACKED_SCAN_1', navitron(scan1), SCAN_RUNS),
                              ('PACKED_SCAN_2', navitron(scan2), SCAN_RUNS)):
        packed = pack(data, runs)
        assert unpack(packed, runs, len(data)) == data
        emit(out, label, packed)
    open(output, 'w').write('\n'.join(out) + '\n')


if __name__ == '__main__':
    main()
