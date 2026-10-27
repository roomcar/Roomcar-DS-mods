#!/usr/bin/env python3
"""Validate compiled hats against the approved pixels and native registration."""
import json
import argparse
from pathlib import Path
import struct
from zipfile import ZipFile
import xml.etree.ElementTree as ET
from PIL import Image
from build_assets import ITEMS, namehash
from asset_io import open_image

ROOT = Path(__file__).resolve().parents[2]
MOD = ROOT/'_Ordinary--DST'


class Reader:
    def __init__(self, data):
        self.data, self.pos = data, 4
    def take(self, fmt):
        result = struct.unpack_from('<'+fmt, self.data, self.pos)
        self.pos += struct.calcsize('<'+fmt)
        return result[0] if len(result) == 1 else result
    def string(self):
        n = self.take('I');value = self.data[self.pos:self.pos+n].decode('utf-8');self.pos += n
        return value


def read_build(data):
    assert data[:4] == b'BILD'
    r = Reader(data);version, ns, nf = r.take('III')
    assert (version, ns, nf) == (6, 2, 4)
    name = r.string();atlases = [r.string() for _ in range(r.take('I'))]
    frames = {}
    for _ in range(ns):
        symbol, count = r.take('II')
        for _ in range(count):
            values = r.take('IIffffII');frames[(symbol, values[0])] = values
    vertices = [r.take('ffffff') for _ in range(r.take('I'))]
    for _ in range(r.take('I')):
        r.take('I');r.string()
    assert r.pos == len(data)
    return name, atlases, frames, vertices


def main():
    global MOD
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--mod-dir', type=Path, help='Validate an alternate build destination')
    args = parser.parse_args()
    if args.mod_dir is not None:
        MOD = args.mod_dir.resolve()
    reg = json.loads((ROOT/'assets/ordinary_series/registration.json').read_text())
    source = {n: open_image({'path':'assets/ordinary_series/hat_layers.zip','member':f'{n}.webp'}) for n in ['solid', 'mesh', 'circlet']}
    source['complete'] = Image.alpha_composite(source['solid'], source['mesh'])
    for prefab, layer in ITEMS:
        with ZipFile(MOD/f'anim/{prefab}.zip') as z:
            assert z.testzip() is None
            name, atlases, frames, vertices = read_build(z.read('build.bin'))
            assert name == prefab and atlases == ['atlas-0.tex']
            tex = z.read(atlases[0]);header = struct.unpack_from('<I', tex, 4)[0]
            assert tex[:4] == b'KTEX' and (header >> 4) & 31 == 4
            mips = (header >> 13) & 31
            width, height, pitch, size = struct.unpack_from('<HHHI', tex, 8)
            atlas = Image.frombytes('RGBA', (width, height), tex[8+10*mips:8+10*mips+size]).transpose(Image.Transpose.FLIP_TOP_BOTTOM)
            assert atlas.getchannel('A').getextrema() == (0, 255)
            for i, d in enumerate(['front', 'side', 'back']):
                f = frames[(namehash('swap_hat'), i)]
                assert f[1] == 1 and f[-1] == 6
                points = vertices[f[-2]:f[-2]+f[-1]]
                art = source[layer].crop((i*724, 0, (i+1)*724, 724))
                box = art.getchannel('A').point(lambda a: 255 if a >= 24 else 0).getbbox()
                expected = [(box[0]-4, box[1]-4), (box[2]+4, box[1]-4), (box[2]+4, box[3]+4), (box[0]-4, box[3]+4)]
                a, b, c, dd, tx, ty, _ = reg['poses'][d]['matrix']
                for v, index in zip(points, [0, 1, 2, 0, 2, 3]):
                    x, y, _, u, vv, sampler = v
                    px = ((a*x+c*y+tx)*2+682-350)*724/700
                    py = ((b*x+dd*y+ty)*2+1538-650)*724/700
                    assert max(abs(px-expected[index][0]), abs(py-expected[index][1])) < .001, (prefab, d, 'registration')
                    assert 0 <= u <= 1 and 0 <= vv <= 1 and sampler == 0
                # Actual compiled alpha must match every approved source pixel.
                ax, ay = (i % 2)*512+4, (i // 2)*512+4
                compiled = atlas.crop((ax, ay, ax+box[2]-box[0], ay+box[3]-box[1]))
                assert compiled.getchannel('A').tobytes() == art.crop(box).getchannel('A').tobytes(), (prefab, d, 'alpha')
            anim = Reader(z.read('anim.bin'))
            assert anim.take('IIIII') == (4, 1, 1, 0, 1)
            assert anim.string() == 'idle'
            facing, bank, rate, count = anim.take('BIfI')
            assert facing == 255 and bank == namehash(prefab) and count == 1
            anim.take('ffff');assert anim.take('II') == (0, 1)
            assert anim.take('III') == (namehash('item'), 0, namehash('item'))
        print('PASS', prefab, 'native registration, lossless alpha, ground animation')
    xml = ET.parse(MOD/'images/inventoryimages/ordinary_hats.xml').getroot()
    assert {e.attrib['name'] for e in xml.findall('./Elements/Element')} == {name+'.tex' for name, _ in ITEMS}
    assert (MOD/'modicon.xml').is_file() and (MOD/'modicon.tex').is_file()
    print('PASS inventory atlas and mod icon')


if __name__ == '__main__':
    main()
