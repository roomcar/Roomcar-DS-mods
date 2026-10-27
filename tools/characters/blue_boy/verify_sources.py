"""Verify loose files and packed source members without changing image content."""
from pathlib import Path
from io import BytesIO
import hashlib,json,sys
from PIL import Image
ROOT=Path(__file__).resolve().parents[3]
sys.path.insert(0,str(ROOT/'tools'))
from asset_io import read_asset
def main():
    manifest=json.loads((ROOT/'assets/characters/blue_boy/manifest.json').read_text(encoding='utf-8'))
    for row in manifest['files']:
        raw=read_asset(row)
        assert hashlib.sha256(raw).hexdigest()==row['sha256'],row
        if row.get('encoding')=='webp_lossless':
            with Image.open(BytesIO(raw)) as im:
                assert list(im.size)==row['size'] and hashlib.sha256(im.convert('RGBA').tobytes()).hexdigest()==row['rgba_sha256']
    print('PASS',len(manifest['files']),'source files/members; SVG bytes and raster RGBA preserved')
if __name__=='__main__':main()
