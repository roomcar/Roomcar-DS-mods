"""Verify, extract or create source-image ZIPs; every archive is at most 32 MB."""
from pathlib import Path, PurePosixPath
from io import BytesIO
from zipfile import ZipFile,ZipInfo,ZIP_DEFLATED
import argparse,hashlib,json
from PIL import Image
from asset_io import ROOT,MAX_ZIP_BYTES,read_asset
from workbench_paths import workbench_root
def verify():
    data=json.loads((ROOT/'assets/image-assets.json').read_text(encoding='utf-8'))
    for pack in data['packages']:
        path=ROOT/pack['path'];raw=path.read_bytes()
        assert len(raw)<=MAX_ZIP_BYTES and hashlib.sha256(raw).hexdigest()==pack['sha256'],pack['path']
        with ZipFile(path) as z:assert z.testzip() is None and len(z.infolist())==pack['members']
    for row in data['images']:
        raw=read_asset(row['storage']);assert hashlib.sha256(raw).hexdigest()==row['sha256'],row['storage']
        with Image.open(BytesIO(raw)) as im:
            assert list(im.size)==row['size'] and hashlib.sha256(im.convert('RGBA').tobytes()).hexdigest()==row['rgba_sha256']
            icc=im.info.get('icc_profile');assert (hashlib.sha256(icc).hexdigest() if icc else None)==row['icc_sha256']
    assert not [p for p in ROOT.rglob('*') if p.is_file() and p.suffix.lower()=='.png' and '.git' not in p.relative_to(ROOT).parts]
    archives=[p for p in ROOT.rglob('*.zip') if '.git' not in p.relative_to(ROOT).parts]
    for path in archives:
        assert path.stat().st_size<=MAX_ZIP_BYTES,path
        with ZipFile(path) as z:assert not any(n.lower().endswith('.png') for n in z.namelist()),path
    print('PASS',len(data['images']),'lossless WebP images,',len(data['packages']),'source ZIPs;',len(archives),'total ZIPs <= 32 MB; zero PNG files')
def extract(package,output):
    data=json.loads((ROOT/'assets/image-assets.json').read_text(encoding='utf-8'));pack=next(p for p in data['packages'] if p['id']==package)
    output=output or workbench_root()/'drafts/image-packages'/package
    output=output.resolve()
    if output==ROOT or ROOT in output.parents:raise ValueError('Extract editable files outside the repository')
    with ZipFile(ROOT/pack['path']) as z:
        for name in z.namelist():
            member=PurePosixPath(name)
            if member.is_absolute() or '..' in member.parts:raise ValueError('Unsafe member')
            target=output/member;raw=z.read(name)
            if target.exists() and target.read_bytes()!=raw:raise FileExistsError(str(target))
        for name in z.namelist():
            target=output/PurePosixPath(name);target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(z.read(name))
    print('Extracted to',output)
def pack(source,output):
    source=source.resolve();output=output.resolve()
    if output.exists():raise FileExistsError('Choose a new candidate archive; do not overwrite current sources')
    buffer=BytesIO()
    with ZipFile(buffer,'w',ZIP_DEFLATED,compresslevel=9) as z:
        for path in sorted(source.rglob('*')):
            if path.is_symlink():raise ValueError('Symlinks are not source members')
            if not path.is_file():continue
            if path.suffix.lower()=='.png':raise ValueError('Convert PNG to lossless WebP first')
            item=ZipInfo(path.relative_to(source).as_posix(),(2026,10,28,0,0,0));item.compress_type=ZIP_DEFLATED;item.external_attr=0o100644<<16
            z.writestr(item,path.read_bytes(),compress_type=ZIP_DEFLATED,compresslevel=9)
    raw=buffer.getvalue()
    if len(raw)>MAX_ZIP_BYTES:raise ValueError('Exceeds 32 MB; split into smaller semantic groups')
    output.parent.mkdir(parents=True,exist_ok=True);output.write_bytes(raw);print('Created candidate:',output,len(raw),'bytes')
def main():
    parser=argparse.ArgumentParser(description=__doc__);sub=parser.add_subparsers(dest='command',required=True)
    sub.add_parser('verify');ex=sub.add_parser('extract');ex.add_argument('package',choices=['head','body','ordinary','mod-art']);ex.add_argument('--output',type=Path)
    pk=sub.add_parser('pack');pk.add_argument('--input',type=Path,required=True);pk.add_argument('--output',type=Path,required=True)
    args=parser.parse_args()
    if args.command=='verify':verify()
    elif args.command=='extract':extract(args.package,args.output)
    else:pack(args.input,args.output)
if __name__=='__main__':main()
