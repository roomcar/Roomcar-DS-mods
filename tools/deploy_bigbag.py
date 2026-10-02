#!/usr/bin/env python3
"""Deploy only the Big Bag local development copy; preserve its display name."""
import argparse
import hashlib
import json
import re
import shutil
import tempfile
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "_BigBag--DST"
DEFAULT = Path.home() / "Library/Application Support/Steam/steamapps/common/Don't Starve Together/dontstarve_steam.app/Contents/mods/roomcar_bigbag_dev"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--destination", type=Path, default=DEFAULT)
    args = parser.parse_args()
    destination = args.destination.expanduser()
    if destination.name != "roomcar_bigbag_dev" or destination.is_symlink():
        parser.error("Destination must be a non-symlink roomcar_bigbag_dev directory")
    name = '" A [DEV] 大背包"'
    existing = destination / "modinfo.lua"
    if existing.exists():
        text = existing.read_text()
        match = re.search(r'^name\s*=\s*(.+)$', text, re.MULTILINE)
        if match and "[DEV]" in match.group(1):
            name = match.group(1)
        backup = Path(tempfile.mkdtemp(prefix="roomcar-bigbag-backup-")) / destination.name
        shutil.copytree(destination, backup)
        print(f"Backup: {backup}")
    destination.mkdir(parents=True, exist_ok=True)
    manifest = {}
    for source in SOURCE.rglob("*"):
        if not source.is_file() or source.name == ".DS_Store":
            continue
        relative = source.relative_to(SOURCE)
        target = destination / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        data = source.read_bytes()
        if relative.as_posix() == "modinfo.lua":
            data = re.sub(r'^name\s*=.*$', lambda _: 'name = ' + name,
                          data.decode(), count=1, flags=re.MULTILINE).encode()
        target.write_bytes(data)
        assert target.read_bytes() == data
        manifest[str(relative)] = hashlib.sha256(data).hexdigest()
    (destination / "dev-deployment.json").write_text(json.dumps({
        "source": str(SOURCE), "deployed_at": datetime.now().astimezone().isoformat(),
        "files": manifest,
    }, ensure_ascii=False, indent=2))
    print(f"Verified {len(manifest)} files in {destination}")


if __name__ == "__main__":
    main()
