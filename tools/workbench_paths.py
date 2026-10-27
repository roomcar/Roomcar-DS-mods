"""Resolve the external Roomcar working directory without creating it on import."""
from pathlib import Path
import os
REPOSITORY = Path(__file__).resolve().parents[1]
def workbench_root(value=None):
    selected = value or os.environ.get("ROOMCAR_WORKBENCH")
    root = Path(selected).expanduser().resolve() if selected else REPOSITORY.with_name(REPOSITORY.name + "-workbench")
    if root == REPOSITORY or REPOSITORY in root.parents:
        raise ValueError("The workbench must be outside the repository")
    return root
