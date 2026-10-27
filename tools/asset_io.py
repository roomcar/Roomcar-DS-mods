"""Read source assets from a loose file or an explicitly named ZIP member."""
from pathlib import Path, PurePosixPath
from io import BytesIO
from zipfile import ZipFile
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
MAX_ZIP_BYTES=32_000_000
def read_asset(reference, root=ROOT):
    ref={'path':str(reference)} if isinstance(reference,(str,Path)) else reference
    path=(root/Path(ref['path'])).resolve()
    if 'member' not in ref:return path.read_bytes()
    member=PurePosixPath(ref['member'])
    if member.is_absolute() or '..' in member.parts:raise ValueError('Unsafe archive member')
    if path.stat().st_size>MAX_ZIP_BYTES:raise ValueError('Archive exceeds 32 MB')
    with ZipFile(path) as z:return z.read(member.as_posix())
def open_image(reference, root=ROOT):
    with Image.open(BytesIO(read_asset(reference,root))) as image:return image.convert('RGBA')
def save_webp(image,path):
    path=Path(path);path.parent.mkdir(parents=True,exist_ok=True)
    image.save(path,format='WEBP',lossless=True,quality=100,method=6,exact=True)
