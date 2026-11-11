#!/usr/bin/env python3
"""Local JSON-in/JSON-out editor for the actual Reason Commons v1 YAML.

No network, shell invocation, publication, or invented import format.
Upstream validation and accepted-history rendering are pinned under vendor/.
"""
from __future__ import annotations

import argparse
import errno
from contextlib import contextmanager
from copy import deepcopy
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import sys
import tempfile
import uuid

VENDOR = Path(__file__).resolve().parent / "vendor" / "reasoncommons"
sys.path.insert(0, str(VENDOR))
try:
    import yaml
    import update_views as upstream
except ImportError as error:
    raise SystemExit("Reason Commons needs PyYAML in this Python environment. See docs/install.md.") from error


# Relations are suggested vocabulary in schema.md; the validator accepts
# any nonempty relation. Keep this list in the bridge and allow custom terms.
RELATION_SUGGESTIONS = (
    "necessary_for", "causes", "contributes_to", "conflicts_with",
    "overcomes", "produces", "precedes",
)


def node_kinds(tree):
    return upstream.KINDS[tree] | {"observation"}


def now():
    return datetime.now(timezone.utc).isoformat()


def digest(data):
    return hashlib.sha256(data).hexdigest()


def require(test, message):
    if not test:
        raise ValueError(message)


def text(request, key):
    value = request.get(key)
    require(isinstance(value, str) and bool(value.strip()), f"{key} must be nonempty text")
    return value


def contribution(state, request):
    actor = text(request, "by")
    require(actor in state["participants"] or actor == "assistant", "Unknown contributor")
    mode = request.get("mode", "text")
    require(mode in {"text", "voice", "unknown"}, "Invalid contribution mode")
    return {"by": actor, "attribution": "assistant" if actor == "assistant" else "explicit", "mode": mode}


def find_item(state, ident):
    for name, tree in state["trees"].items():
        for category in ("nodes", "links"):
            for item in tree[category]:
                if item["id"] == ident:
                    return name, category, item
    raise ValueError("Unknown reasoning item")


def demote_incident(tree, ident):
    for link in tree["links"]:
        if link.get("status") == "accepted" and (ident in link["from"] or ident == link["to"]):
            link["status"] = "proposed"


def transform(state, request):
    """Apply one operation in memory; no filesystem writes on invalid input."""
    operation = request["op"]
    actor = text(request, "by")
    require(actor in state["participants"] or actor == "assistant", "Unknown actor")
    tree_name = request.get("tree", state["active_tree"])
    require(tree_name in upstream.KINDS, "Unknown tree family")
    if operation in {"add-node", "add-link"}:
        tree = state["trees"].setdefault(tree_name, {"nodes": [], "links": [], "backlog": []})
        if operation == "add-node":
            ident = "n-" + str(uuid.uuid4())
            item = {"id": ident, "kind": text(request, "kind"), "text": text(request, "text"),
                    "status": "proposed", "contributions": [contribution(state, request)]}
            require(item["kind"] in node_kinds(tree_name), "Kind does not belong to this tree")
            tree["nodes"].append(item)
        else:
            ident = "l-" + str(uuid.uuid4())
            sources = request.get("from")
            target = text(request, "to")
            require(isinstance(sources, list) and sources and all(isinstance(s, str) for s in sources), "from must be a nonempty node-ID list")
            require(len(set(sources)) == len(sources), "Duplicate sources conceal an AND condition")
            require(target not in sources, "Use distinct, time-qualified propositions for a feedback loop")
            item = {"id": ident, "from": sources, "to": target, "relation": text(request, "relation"),
                    "status": "proposed", "contributions": [contribution(state, request)]}
            tree["links"].append(item)
        state["active_tree"] = tree_name
        return {"id": ident, "tree": tree_name, "status": "proposed"}

    name, category, item = find_item(state, text(request, "id"))
    tree = state["trees"][name]
    if operation == "accept":
        require(actor in state["participants"], "Only a configured human can endorse reasoning")
        require(item.get("status") != "disputed", "Resolve the recorded challenge in YAML or the LTP workflow before endorsement")
        if category == "links":
            nodes = {n["id"]: n for n in tree["nodes"]}
            require(all(nodes[n].get("status") == "accepted" for n in item["from"] + [item["to"]]), "Endorse all endpoints before endorsing this relationship")
        item["status"] = "accepted"
        item["accepted_by"] = sorted(set(item.get("accepted_by", [])) | {actor})
    elif operation in {"challenge", "assumption"}:
        key = "challenges" if operation == "challenge" else "assumptions"
        item.setdefault(key, []).append({"text": text(request, "text"), "by": actor})
        item["status"] = "disputed" if operation == "challenge" else "proposed"
        if category == "nodes":
            demote_incident(tree, item["id"])
        work = "resolve_challenge" if operation == "challenge" else "examine_assumption"
        if not any(b["ref"] == item["id"] and b["work"] == work for b in tree["backlog"]):
            tree["backlog"].append({"ref": item["id"], "work": work})
    elif operation == "backlog":
        work = text(request, "work")
        if not any(b["ref"] == item["id"] and b["work"] == work for b in tree["backlog"]):
            tree["backlog"].append({"ref": item["id"], "work": work})
    else:
        raise ValueError("Unknown operation")
    return {"id": item["id"], "tree": name, "status": item.get("status", "proposed")}


def write_new(path, data):
    """Exclusive creation with private permissions."""
    path.parent.mkdir(parents=True, exist_ok=True)
    # O_BINARY (Windows only): text mode would turn \n into \r\n and break digests.
    descriptor = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL | getattr(os, "O_BINARY", 0), 0o600)
    with os.fdopen(descriptor, "wb") as handle:
        handle.write(data)
        handle.flush()
        os.fsync(handle.fileno())


@contextmanager
def lock(path):
    # Keep the inode in place. Unlinking it can let two writers lock different
    # files. Closing the descriptor, including on process death, releases it.
    lockfile = path.parent / ".org-reason" / (path.name + ".lock")
    lockfile.parent.mkdir(mode=0o700, exist_ok=True)
    descriptor = os.open(lockfile, os.O_RDWR | os.O_CREAT, 0o600)
    try:
        try:
            if os.name == "nt":
                import msvcrt
                msvcrt.locking(descriptor, msvcrt.LK_NBLCK, 1)
            else:
                import fcntl
                fcntl.flock(descriptor, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except OSError as error:
            if error.errno not in {errno.EACCES, errno.EAGAIN, errno.EDEADLK}:
                raise
            raise ValueError(f"Another process is editing {path.name}; retry when it finishes") from error
        yield
    finally:
        os.close(descriptor)


def replace_checked(path, data, expected_digest):
    require(digest(path.read_bytes()) == expected_digest, "File changed during this edit; reload and retry")
    with tempfile.NamedTemporaryFile(dir=path.parent, prefix=".org-reason-", delete=False) as handle:
        temporary = Path(handle.name)
        handle.write(data)
        handle.flush()
        os.fsync(handle.fileno())
    try:
        require(digest(path.read_bytes()) == expected_digest, "File changed during this edit; reload and retry")
        os.chmod(temporary, path.stat().st_mode & 0o777)
        os.replace(temporary, path)
    finally:
        temporary.unlink(missing_ok=True)


def execute(path, request):
    path = Path(path).expanduser().resolve()
    operation = text(request, "op")
    if operation == "new":
        participant = text(request, "participant")
        require(participant != "assistant", "The driver must be a human participant")
        tree = request.get("tree", "goal")
        require(tree in upstream.KINDS, "Unknown tree family")
        state = {"schema_version": 1, "project": text(request, "project"), "driver": participant,
                 "participants": {participant: text(request, "name")}, "active_tree": tree,
                 "trees": {tree: {"nodes": [], "links": [], "backlog": []}}}
        upstream.validate(state)
        data = yaml.safe_dump(state, sort_keys=False, allow_unicode=True).encode("utf-8")
        write_new(path, data)
        return {"saved": True, "sha256": digest(data), "state": state}

    if operation == "inspect":
        raw = path.read_bytes()
        # Parse the same bytes we hash; reject duplicate keys with the upstream loader.
        state = yaml.load(raw.decode("utf-8"), Loader=upstream.StateLoader)
        upstream.validate(state)
        return {"sha256": digest(raw), "state": state,
                "tree_kinds": {tree: sorted(node_kinds(tree)) for tree in upstream.KINDS},
                "relation_suggestions": RELATION_SUGGESTIONS}

    if operation == "views":
        with lock(path):
            return upstream.update(path)

    with lock(path):
        raw = path.read_bytes()
        before_digest = digest(raw)
        require(request.get("expected_sha256") == before_digest,
                "The file differs from the version you reviewed; inspect it again")
        state = yaml.load(raw.decode("utf-8"), Loader=upstream.StateLoader)
        upstream.validate(state)
        before = deepcopy(state)
        result = transform(state, request)
        upstream.validate(state)
        upstream.feedback.guard_transition(before, state)
        data = yaml.safe_dump(state, sort_keys=False, allow_unicode=True).encode("utf-8")
        history = path.parent / ".org-reason" / "history"
        event_id = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ") + "-" + uuid.uuid4().hex[:10]
        write_new(history / (event_id + ".yaml"), raw)
        replace_checked(path, data, before_digest)
        result.update(saved=True, sha256=digest(data))
        try:
            write_new(history / (event_id + ".json"), json.dumps({"at": now(), "op": operation,
                      "actor": request.get("by"), "item": result.get("id"), "before_sha256": before_digest,
                      "after_sha256": digest(data)}, ensure_ascii=False, indent=2).encode("utf-8"))
        except OSError as error:
            result["history_warning"] = str(error)
        try:
            result["views"] = upstream.update(path, summary=f"Org Reason: {operation}")
        except (ValueError, KeyError, TypeError, AttributeError, OSError, RuntimeError, yaml.YAMLError) as error:
            # The valid YAML is already saved. Never pretend the edit failed and invite a duplicate.
            result["view_error"] = str(error)
        return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--file", required=True, type=Path)
    args = parser.parse_args()
    try:
        request = json.load(sys.stdin)
        require(isinstance(request, dict), "Request must be a JSON object")
        print(json.dumps(execute(args.file, request), ensure_ascii=False))
        return 0
    except (ValueError, KeyError, TypeError, AttributeError, OSError, RuntimeError, yaml.YAMLError) as error:
        print(f"org-reason: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
