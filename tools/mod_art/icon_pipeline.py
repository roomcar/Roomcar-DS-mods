#!/usr/bin/env python3
"""Rebuild Roomcar's approved layered mod icons without changing source assets."""
import argparse
import sys
import json
from pathlib import Path
import subprocess
import tempfile

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / 'assets' / 'mod_art'
sys.path.insert(0, str(ROOT / 'tools'))
from workbench_paths import workbench_root
from asset_io import open_image, save_webp


def save_image(image, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.suffix.lower()=='.webp':save_webp(image,path)
    else:image.save(path,optimize=True)


def game_icon(preset, output, size):
    frame = open_image({'path':str(ASSETS/preset['archive']),'member':preset['frame']})
    width, height = frame.size
    mask = open_image({'path':str(ASSETS/preset['archive']),'member':preset['backplate']}).getchannel('A')
    yy, xx = np.mgrid[0:height, 0:width]
    gradient = preset['gradient']
    radius = np.sqrt((xx / width - gradient['center'][0]) ** 2
                     + (yy / height - gradient['center'][1]) ** 2)
    u = np.clip(radius / gradient['radius'], 0, 1)
    blend = u * u * (3 - 2 * u)
    center, edge = np.array(gradient['center_rgb']), np.array(gradient['edge_rgb'])
    rgb = np.rint(center[None, None, :] * (1 - blend[:, :, None])
                  + edge[None, None, :] * blend[:, :, None]).astype('uint8')
    backplate = Image.fromarray(rgb).convert('RGBA')
    backplate.putalpha(mask)

    pixels = np.array(frame)
    ink = pixels[:, :, :3].max(axis=2) <= preset['black_threshold']
    original_ink = pixels[:, :, :3][ink].copy()
    neutral = pixels[:, :, :3].mean(axis=2)
    tinted = np.rint(neutral[:, :, None]
                     * (np.array(preset['frame_rgb']) / 255)).astype('uint8')
    tinted[ink] = original_ink
    pixels[:, :, :3] = tinted
    coloured_frame = Image.fromarray(pixels)
    assert np.array_equal(np.array(coloured_frame)[:, :, 3], np.array(frame)[:, :, 3])
    assert np.array_equal(np.array(coloured_frame)[:, :, :3][ink], original_ink)

    subject = Image.new('RGBA', frame.size)
    for layer in preset['layers']:
        part = open_image({'path':str(ASSETS/preset['archive']),'member':layer['file']})
        if part.size != tuple(layer['size']):
            part = part.resize(tuple(layer['size']), Image.Resampling.LANCZOS)
        subject.alpha_composite(part, tuple(layer['position']))
    master = Image.new('RGBA', frame.size, 'black')
    for layer in (backplate, subject, coloured_frame):
        master.alpha_composite(layer)
    save_image(backplate, output / 'backplate.webp')
    save_image(coloured_frame, output / 'frame.webp')
    save_image(master, output / 'icon-master.webp')
    save_image(master.resize((size, size), Image.Resampling.LANCZOS), output / 'godhaticon.webp')


def workshop_cover(art_path, output, size):
    # The source perimeter preserves the original texture and subpixel corners.
    frame = open_image({'path':str(ASSETS/'icon_layers.zip'),'member':'workshop-frame-purple.webp'})
    inset = round(10 * size / 512)
    art = Image.open(art_path).convert('RGBA').resize(
        (size - 2 * inset, size - 2 * inset), Image.Resampling.LANCZOS)
    result = Image.new('RGBA', (size, size), 'black')
    result.alpha_composite(art, (inset, inset))
    result.alpha_composite(frame.resize((size, size), Image.Resampling.LANCZOS))
    save_image(result.convert('RGB'), output)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--work-root', type=Path, help='External workbench root')
    commands = parser.add_subparsers(dest='command', required=True)
    game = commands.add_parser('game', help='Compose the approved layered game icon')
    game.add_argument('--preset', type=Path, default=Path(__file__).with_name('oracle.json'))
    game.add_argument('--output-dir', type=Path)
    game.add_argument('--size', type=int, default=512)
    cover = commands.add_parser('cover', help='Frame a separately generated square artwork')
    cover.add_argument('--art', type=Path, required=True)
    cover.add_argument('--output', type=Path)
    cover.add_argument('--size', type=int, default=1024)
    compile_icon = commands.add_parser('compile', help='Run the installed official TextureConverter')
    compile_icon.add_argument('--converter', type=Path, required=True)
    compile_icon.add_argument('--image', type=Path, required=True)
    compile_icon.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    output_root = workbench_root(args.work_root) / 'build/mod_art'
    if args.command == 'game':
        args.output_dir = args.output_dir or output_root / 'oracle'
        if args.size < 1:
            parser.error('--size must be positive')
        game_icon(json.loads(args.preset.read_text('utf8')), args.output_dir, args.size)
    elif args.command == 'cover':
        args.output = args.output or output_root / 'workshop-cover.webp'
        if args.size < 1:
            parser.error('--size must be positive')
        workshop_cover(args.art, args.output, args.size)
    else:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        output_root.mkdir(parents=True,exist_ok=True)
        with tempfile.TemporaryDirectory(prefix='texture-',dir=output_root) as temp:
            source=args.image.resolve()
            if source.suffix.lower()=='.webp':
                png=Path(temp)/'input.png'
                with Image.open(source) as image:image.save(png,format='PNG')
                source=png
            subprocess.run([str(args.converter.resolve()), '--format', 'argb', '--platform',
                            'opengl', '--premultiply', '--mipmap', '-i', str(source),
                            '-o', str(args.output.resolve())], check=True)


if __name__ == '__main__':
    main()
