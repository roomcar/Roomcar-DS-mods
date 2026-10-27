#!/usr/bin/env python3
"""Compile the approved hat layers with the official Klei texture converter."""
import argparse
import sys
import json
from pathlib import Path
import struct
import subprocess
import xml.etree.ElementTree as ET
from zipfile import ZipFile, ZIP_DEFLATED

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'assets/ordinary_series'
MOD = ROOT / '_Ordinary--DST'
sys.path.insert(0, str(ROOT / 'tools'))
from workbench_paths import workbench_root
from asset_io import open_image, save_webp
WORK = workbench_root() / 'build/ordinary_series'
ITEMS = [('roomcar_tattered_hat_base', 'solid'),
         ('roomcar_tattered_hat_mesh', 'mesh'), ('roomcar_tattered_hat', 'complete'),
         ('roomcar_plain_circlet', 'circlet')]


def pack(fmt, *values):
    return struct.pack('<' + fmt, *values)


def string(value):
    data = value.encode('utf-8')
    return pack('I', len(data)) + data


def namehash(value):
    result = 0
    for char in value.lower():
        result = (ord(char) + (result << 6) + (result << 16) - result) & 0xffffffff
    return result


def texture(converter, source, target):
    target.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run([str(converter), '--format', 'argb', '--platform', 'opengl',
                    '--premultiply', '--mipmap', '-i', str(source), '-o', str(target)],
                   check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)


def bbox(points):
    xs, ys = zip(*points)
    l, r, t, b = min(xs), max(xs), min(ys), max(ys)
    return [(l+r)/2, (t+b)/2, r-l, b-t]


def buildbin(name, frames):
    # Public format documented by the installed official buildanimation.py.
    symbols = ['swap_hat', 'item']
    data = b'BILD' + pack('III', 6, 2, len(frames)) + string(name)
    data += pack('I', 1) + string('atlas-0.tex')
    vertices = []
    for symbol in symbols:
        group = [frame for frame in frames if frame['symbol'] == symbol]
        data += pack('II', namehash(symbol), len(group))
        for frame in group:
            points = frame['points']
            data += pack('IIffffII', frame['index'], 1, *bbox(points), len(vertices), 6)
            uv = frame['uv']
            for index in [0, 1, 2, 0, 2, 3]:
                vertices.append((*points[index], 0., *uv[index], 0.))
    data += pack('I', len(vertices))
    data += b''.join(pack('ffffff', *v) for v in vertices)
    data += pack('I', len(symbols))
    for symbol in symbols:
        data += pack('I', namehash(symbol)) + string(symbol)
    return data


def animbin(name, ground):
    names = [name, 'item']
    data = b'ANIM' + pack('IIIII', 4, 1, 1, 0, 1)
    data += string('idle') + pack('BIfI', 255, namehash(name), 30., 1)
    data += pack('ffff', *bbox(ground)) + pack('II', 0, 1)
    data += pack('IIIfffffff', namehash('item'), 0, namehash('item'), 1., 0., 0., 1., 0., 0., 0.)
    data += pack('I', len(names))
    for text in names:
        data += pack('I', namehash(text)) + string(text)
    return data


def compile_item(name, art, registration, converter):
    folder = WORK / name
    folder.mkdir(parents=True, exist_ok=True)
    atlas = Image.new('RGBA', (1024, 1024))
    frames = []
    for i, direction in enumerate(['front', 'side', 'back']):
        cell = art.crop((i*724, 0, (i+1)*724, 724))
        bounds = cell.getchannel('A').point(lambda x: 255 if x >= 24 else 0).getbbox()
        assert bounds is not None
        crop = cell.crop(bounds)
        image = Image.new('RGBA', (crop.width+8, crop.height+8))
        image.paste(crop, (4, 4))
        assert image.width <= 512 and image.height <= 512
        x, y = (i % 2)*512, (i // 2)*512
        atlas.paste(image, (x, y))
        uv = [(x/1024, 1-y/1024), ((x+image.width)/1024, 1-y/1024),
              ((x+image.width)/1024, 1-(y+image.height)/1024), (x/1024, 1-(y+image.height)/1024)]
        a, b, c, d, tx, ty, _ = registration['poses'][direction]['matrix']
        det = a*d-b*c
        def logical(px, py):
            canvasx = 350 + (bounds[0]+px-4)*700/724
            canvasy = 650 + (bounds[1]+py-4)*700/724
            worldx = (canvasx-682)/2-tx
            worldy = (canvasy-1538)/2-ty
            return ((d*worldx-c*worldy)/det, (-b*worldx+a*worldy)/det)
        corners = [(0, 0), (image.width, 0), (image.width, image.height), (0, image.height)]
        frames.append({'symbol': 'swap_hat', 'index': i, 'points': [logical(*p) for p in corners], 'uv': uv})
        if i == 0:
            # The same approved front pixels supply a small ground sprite.
            ratio = 90/crop.width
            ground = [((px-4-crop.width/2)*ratio, (py-4-crop.height)*ratio) for px, py in corners]
            groundframe = {'symbol': 'item', 'index': 0, 'points': ground, 'uv': uv}
    frames.append(groundframe)
    atlas.save(folder/'atlas.png')
    texture(converter, folder/'atlas.png', folder/'atlas-0.tex')
    destination = MOD/'anim'/f'{name}.zip'
    destination.parent.mkdir(parents=True, exist_ok=True)
    with ZipFile(destination, 'w', ZIP_DEFLATED) as output:
        output.writestr('build.bin', buildbin(name, frames))
        output.writestr('anim.bin', animbin(name, groundframe['points']))
        output.write(folder/'atlas-0.tex', 'atlas-0.tex')
    return {'prefab': name, 'frames': frames}


def inventory_and_modicon(art, converter):
    atlas = Image.new('RGBA', (256, 256))
    xml = ET.Element('Atlas')
    ET.SubElement(xml, 'Texture', filename='ordinary_hats.tex')
    elements = ET.SubElement(xml, 'Elements')
    for i, (name, layer) in enumerate(ITEMS):
        im = art[layer].crop((0, 0, 724, 724))
        bounds = im.getchannel('A').point(lambda x: 255 if x >= 24 else 0).getbbox()
        im = im.crop(bounds)
        im.thumbnail((112, 112), Image.Resampling.LANCZOS)
        x, y = i % 2*128, i // 2*128
        atlas.alpha_composite(im, (x+(128-im.width)//2, y+(128-im.height)//2))
        ET.SubElement(elements, 'Element', name=name+'.tex', u1=str(x/256), u2=str((x+128)/256),
                      v1=str(1-(y+128)/256), v2=str(1-y/256))
    atlas.save(WORK/'inventory.png')
    target = MOD/'images/inventoryimages';target.mkdir(parents=True, exist_ok=True)
    texture(converter, WORK/'inventory.png', target/'ordinary_hats.tex')
    ET.indent(xml)
    ET.ElementTree(xml).write(target/'ordinary_hats.xml', encoding='utf-8', xml_declaration=True)
    icon = Image.new('RGBA', (512, 512), '#d0c8b6')
    draw = ImageDraw.Draw(icon)
    draw.rectangle((12, 12, 499, 499), outline='#29251f', width=9)
    im = art['complete'].crop((0, 0, 724, 724))
    im = im.crop(im.getchannel('A').point(lambda x: 255 if x >= 24 else 0).getbbox())
    im.thumbnail((410, 370), Image.Resampling.LANCZOS)
    icon.alpha_composite(im, ((512-im.width)//2, (512-im.height)//2))
    save_webp(icon, MOD/'modicon.webp')
    icon.save(WORK/'modicon.png')
    texture(converter, WORK/'modicon.png', MOD/'modicon.tex')
    (MOD/'modicon.xml').write_text('<Atlas><Texture filename="modicon.tex"/><Elements>'
        '<Element name="modicon.tex" u1="0" u2="1" v1="0" v2="1"/>'
        '</Elements></Atlas>\n', encoding='utf-8')


def main():
    global WORK, MOD
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--converter', type=Path, required=True)
    parser.add_argument('--work-root', type=Path, help='External workbench root')
    parser.add_argument('--mod-dir', type=Path, help='Optional destination for a verification build')
    args = parser.parse_args()
    WORK = workbench_root(args.work_root) / 'build/ordinary_series'
    if args.mod_dir is not None:
        MOD = args.mod_dir.resolve()
    WORK.mkdir(parents=True, exist_ok=True)
    art = {name: open_image({'path':'assets/ordinary_series/hat_layers.zip','member':f'{name}.webp'}) for name in ['solid', 'mesh', 'circlet']}
    assert all(im.size == (2172, 724) for im in art.values())
    art['complete'] = Image.alpha_composite(art['solid'], art['mesh'])
    registration = json.loads((SOURCE/'registration.json').read_text(encoding='utf-8'))
    assert registration['layer_order'] == ['solid', 'mesh']
    results = [compile_item(name, art[layer], registration, args.converter.resolve()) for name, layer in ITEMS]
    inventory_and_modicon(art, args.converter.resolve())
    (WORK/'build-manifest.json').write_text(json.dumps(results, indent=2), encoding='utf-8')
    print('Built four head items, inventory atlas and mod icon:', MOD)


if __name__ == '__main__':
    main()
