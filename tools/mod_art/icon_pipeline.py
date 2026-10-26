#!/usr/bin/env python3
"""Rebuild Roomcar's approved layered mod icons without changing source assets."""
import argparse
import json
from pathlib import Path
import subprocess

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / 'assets' / 'mod_art'


def save_png(image, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, optimize=True)


def game_icon(preset, output, size):
    frame = Image.open(ASSETS / preset['frame']).convert('RGBA')
    width, height = frame.size
    mask = Image.open(ASSETS / preset['backplate']).getchannel('A')
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
        part = Image.open(ASSETS / layer['file']).convert('RGBA')
        if part.size != tuple(layer['size']):
            part = part.resize(tuple(layer['size']), Image.Resampling.LANCZOS)
        subject.alpha_composite(part, tuple(layer['position']))
    master = Image.new('RGBA', frame.size, 'black')
    for layer in (backplate, subject, coloured_frame):
        master.alpha_composite(layer)
    save_png(backplate, output / 'backplate.png')
    save_png(coloured_frame, output / 'frame.png')
    save_png(master, output / 'icon-master.png')
    save_png(master.resize((size, size), Image.Resampling.LANCZOS), output / 'godhaticon.png')


def workshop_cover(art_path, output, size):
    # The source perimeter preserves the original texture and subpixel corners.
    frame = Image.open(ASSETS / 'workshop-frame-purple.png').convert('RGBA')
    inset = round(10 * size / 512)
    art = Image.open(art_path).convert('RGBA').resize(
        (size - 2 * inset, size - 2 * inset), Image.Resampling.LANCZOS)
    result = Image.new('RGBA', (size, size), 'black')
    result.alpha_composite(art, (inset, inset))
    result.alpha_composite(frame.resize((size, size), Image.Resampling.LANCZOS))
    save_png(result.convert('RGB'), output)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest='command', required=True)
    game = commands.add_parser('game', help='Compose the approved layered game icon')
    game.add_argument('--preset', type=Path, default=Path(__file__).with_name('oracle.json'))
    game.add_argument('--output-dir', type=Path, required=True)
    game.add_argument('--size', type=int, default=512)
    cover = commands.add_parser('cover', help='Frame a separately generated square artwork')
    cover.add_argument('--art', type=Path, required=True)
    cover.add_argument('--output', type=Path, required=True)
    cover.add_argument('--size', type=int, default=1024)
    compile_icon = commands.add_parser('compile', help='Run the installed official TextureConverter')
    compile_icon.add_argument('--converter', type=Path, required=True)
    compile_icon.add_argument('--image', type=Path, required=True)
    compile_icon.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    if args.command == 'game':
        if args.size < 1:
            parser.error('--size must be positive')
        game_icon(json.loads(args.preset.read_text('utf8')), args.output_dir, args.size)
    elif args.command == 'cover':
        if args.size < 1:
            parser.error('--size must be positive')
        workshop_cover(args.art, args.output, args.size)
    else:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        subprocess.run([str(args.converter.resolve()), '--format', 'argb', '--platform',
                        'opengl', '--premultiply', '--mipmap', '-i', str(args.image.resolve()),
                        '-o', str(args.output.resolve())], check=True)


if __name__ == '__main__':
    main()
