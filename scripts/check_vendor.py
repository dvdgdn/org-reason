"""Check the vendored Reason Commons files against their pinned hashes."""
import hashlib
import json
from pathlib import Path
import sys

VENDOR = Path(__file__).resolve().parents[1] / "vendor" / "reasoncommons"
pinned = json.loads((VENDOR / "UPSTREAM.json").read_text())["files"]
changed = [name for name, digest in pinned.items()
           if hashlib.sha256((VENDOR / name).read_bytes()).hexdigest() != digest]
if changed:
    sys.exit("Changed from the pinned upstream revision: " + ", ".join(changed))
print(f"{len(pinned)} vendored files match UPSTREAM.json")
