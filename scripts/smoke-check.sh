#!/usr/bin/env bash
# Deterministic smokes for atlas-tasks (v0.8.0 — writer script + recall alias + task lists; contract-key-only overlay).
# Usage:
#   smoke-check.sh <atlas-tasks-package-root>
#   smoke-check.sh <atlas-tasks-package-root> --check <name>
# Named checks: cycle-reject | orphan-sub-tasks | no-blocked-status | assignees-list |
#               frontmatter-keys | status-enum | dual-write | overlay-claim | overlay-root-keys |
#               package-identity |
#               no-depends_on-field | dual-write-blocks | non-task-dependency |
#               blocked-from-dependency | dependency-terminal | dependency-cycle |
#               task-id-atlas-uri | physical-path-ulid | no-kebab-id | human-facing-ulid |
#               cross-atlas-dependency | same-atlas-parent | fail-closed-remote |
#               task-list-suffix-matches-type | listed-task-not-loose-on-index |
#               list-link-does-not-copy-tasks | rename-keeps-ulid-uri |
#               member-lives-in-list-folder | membership-both-sides | filename-ulid-and-name |
#               recall-alias | no-mandatory-notes-or-vault-tool | list-folder-index |
#               tasks-writer |
#               (default: all)
set -euo pipefail
PKG_ROOT="${1:-}"
if [[ -z "$PKG_ROOT" || ! -d "$PKG_ROOT" ]]; then
  echo "usage: smoke-check.sh <atlas-tasks-package-root> [--check <name>]" >&2
  exit 2
fi
shift || true
CHECK_ONLY=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --check) CHECK_ONLY="${2:-}"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

SKILL="$PKG_ROOT"
OVERLAY="$SKILL/contributions/atlas-tasks/SCHEMA.overlay.json"
README_CONTRIB="$SKILL/contributions/atlas-tasks/README.md"
ATLAS_CLI=${ATLAS_CLI:-}
if [[ -z "$ATLAS_CLI" ]]; then
  # Sibling installed `atlas` skill (e.g. .agents/skills/atlas next to .agents/skills/atlas-tasks).
  sibling_cli="$(cd "$PKG_ROOT" && pwd)/../atlas/scripts/atlas.py"
  if [[ -f "$sibling_cli" ]]; then
    ATLAS_CLI=$sibling_cli
  else
    echo "atlas.py not found: set ATLAS_CLI to the Atlas CLI (scripts/atlas.py of the atlas skill)" >&2
    exit 2
  fi
fi

fail() { echo "FAIL: $*" >&2; exit 1; }
pass() { echo "PASS: $*"; }

want() {
  if [[ -z "$CHECK_ONLY" ]]; then return 0; fi
  [[ "$CHECK_ONLY" == "$1" ]]
}

# ---------------------------------------------------------------------------
# v1 layout / authority (always with full run)
# ---------------------------------------------------------------------------
if [[ -z "$CHECK_ONLY" ]]; then
  [[ -f "$SKILL/SKILL.md" ]] || fail "missing SKILL.md"
  grep -q 'apm-toolkit' "$PKG_ROOT/apm.yml" && fail "apm.yml must not depend on apm-toolkit" || true
  pass "1 layout + no apm-toolkit dep"

  [[ -f "$OVERLAY" ]] || fail "missing overlay"
  grep -q '"contribution_id": "atlas-tasks"' "$OVERLAY" || fail "bad contribution_id"
  [[ ! -d "$SKILL/contributions/atlas-todo" ]] || fail "legacy contributions/atlas-todo must be absent"
  grep -qE '^name: atlas-tasks$' "$SKILL/SKILL.md" || fail "SKILL name must be atlas-tasks"
  grep -qE 'version: "0\.8\.0"' "$PKG_ROOT/apm.yml" || fail "apm.yml version must be 0.8.0"
  python3 - <<PY || fail "overlay extend-not-replace"
import json,sys
o=json.load(open("$OVERLAY"))
bt=(o.get("templates") or {}).get("by_type") or {}
if "task" in bt:
    sys.exit("overlay must not redeclare core task")
if "todo" in bt:
    sys.exit("rival primary type todo forbidden")
cf = o.get("claimed_folders") or []
if "tasks" not in cf:
    sys.exit("must claim tasks/")
if "todo" in cf:
    sys.exit("must not claim todo/")
print("ok")
PY
  pass "2 overlay present + extend-not-replace (tasks/ only)"

  python3 - <<'PY' || fail "negative gate"
atlas_id = ""  # missing
if not atlas_id.strip():
    print("fail-closed: missing Atlas id")
else:
    raise SystemExit("should have failed closed")
PY
  pass "5 fail closed without Atlas id"
fi

# ---------------------------------------------------------------------------
# Shared Python helpers for relation smokes
# ---------------------------------------------------------------------------
HELPERS=$(mktemp)
cat > "$HELPERS" <<'PY'
import re, sys
from pathlib import Path

ALLOWED_STATUS = {"open", "in_progress", "done", "cancelled"}
FORBIDDEN_STATUS = {"blocked", "duplicate"}
ULID_RE = re.compile(r"^[0-9A-HJKMNP-TV-Z]{26}$")
ATLAS_URI_RE = re.compile(r"^atlas://([^/]+(?:/[^/]+)*)/tasks/([0-9A-HJKMNP-TV-Z]{26})$")

def parse_fm(text: str) -> dict:
    if not text.startswith("---"):
        return {}
    end = text.find("\n---", 3)
    if end < 0:
        return {}
    block = text[3:end]
    data = {}
    lines = block.splitlines()
    i = 0
    while i < len(lines):
        line = lines[i]
        if not line.strip() or line.strip().startswith("#"):
            i += 1
            continue
        m = re.match(r"^([A-Za-z0-9_]+):\s*(.*)$", line)
        if not m:
            i += 1
            continue
        key, rest = m.group(1), m.group(2).strip()
        if rest == "" or rest == "|" or rest == ">":
            items = []
            i += 1
            while i < len(lines):
                lm = re.match(r"^\s+-\s+(.*)$", lines[i])
                if not lm:
                    break
                item_rest = lm.group(1).strip()
                km = re.match(r"^([A-Za-z0-9_]+):\s*(.*)$", item_rest)
                if km and (i + 1 < len(lines)) and re.match(r"^\s{4,}[A-Za-z0-9_]+:", lines[i + 1] or ""):
                    obj = {km.group(1): km.group(2).strip().strip("'\"")}
                    i += 1
                    while i < len(lines):
                        if lines[i].lstrip().startswith("-"):
                            break
                        nm = re.match(r"^\s{2,}([A-Za-z0-9_]+):\s*(.*)$", lines[i])
                        if not nm:
                            break
                        obj[nm.group(1)] = nm.group(2).strip().strip("'\"")
                        i += 1
                    items.append(obj)
                    continue
                elif km and key == "relates_to":
                    obj = {km.group(1): km.group(2).strip().strip("'\"")}
                    i += 1
                    while i < len(lines):
                        if re.match(r"^\s+-\s+", lines[i]):
                            break
                        nm = re.match(r"^\s{2,}([A-Za-z0-9_]+):\s*(.*)$", lines[i])
                        if not nm:
                            break
                        obj[nm.group(1)] = nm.group(2).strip().strip("'\"")
                        i += 1
                    items.append(obj)
                    continue
                else:
                    items.append(item_rest.strip("'\""))
                    i += 1
            data[key] = items
            continue
        if rest.startswith("[") and rest.endswith("]"):
            inner = rest[1:-1].strip()
            if not inner:
                data[key] = []
            else:
                data[key] = [p.strip().strip("'\"") for p in inner.split(",")]
        elif rest in ("null", "~", ""):
            data[key] = None
        else:
            data[key] = rest.strip("'\"")
        i += 1
    return data

def is_atlas_uri(tid: str) -> bool:
    return bool(ATLAS_URI_RE.match(tid or ""))

def parse_atlas_uri(tid: str):
    m = ATLAS_URI_RE.match(tid or "")
    if not m:
        return None, None
    return m.group(1), m.group(2)

def ulid_of(tid: str) -> str | None:
    _, u = parse_atlas_uri(tid)
    return u

def atlas_of(tid: str) -> str | None:
    a, _ = parse_atlas_uri(tid)
    return a

def path_for(ulid: str, name: str, folder: str = "tasks") -> str:
    """v0.6 task pointer: <folder>/<ULID>-<name>.md (root or a list folder).

    Not the retired tasks/<ULID>.md shape. name is the file-safe stem.
    """
    if not isinstance(name, str) or not name or "/" in name or name.endswith(".md"):
        raise ValueError("path_for requires a file-safe name")
    return f"{folder.rstrip('/')}/{ulid}-{name}.md"

def task_id_for(atlas_id: str, ulid: str) -> str:
    return f"atlas://{atlas_id}/tasks/{ulid}"

def reject_kebab(tid: str) -> bool:
    """True if tid looks like a legacy kebab (not atlas:// URI)."""
    if not tid:
        return False
    if is_atlas_uri(tid):
        return False
    if ULID_RE.match(tid):
        return False  # bare ULID lookup ok; not a kebab slug id
    return True

def dependency_paths(pointer: dict) -> list:
    out = []
    for e in pointer.get("relates_to") or []:
        if isinstance(e, dict) and e.get("kind") == "dependency":
            out.append(e.get("path"))
    return out

def blocks_paths(pointer: dict) -> list:
    out = []
    for e in pointer.get("relates_to") or []:
        if isinstance(e, dict) and e.get("kind") == "blocks":
            out.append(e.get("path"))
    return out

NAMED_POINTER_RE = re.compile(
    r"(?:^|/)([0-9A-HJKMNP-TV-Z]{26})-[a-z0-9]+(?:-[a-z0-9]+)*\.md$"
)

def resolve_tid(pointers: dict, ref: str, atlas_id: str | None = None):
    """Resolve atlas://, <ULID>-<name>.md (tasks/ or a list folder), or bare ULID.

    tasks/<ULID>.md is not a v0.6 pointer and does not resolve.
    .task-list.md paths are lists, not task dependency targets.
    """
    if not ref:
        return None
    if ref in pointers:
        return ref
    m = ATLAS_URI_RE.match(ref)
    if m:
        tid = ref
        return tid if tid in pointers else None
    if isinstance(ref, str) and not ref.endswith(".task-list.md"):
        m = NAMED_POINTER_RE.search(ref)
        if m and atlas_id:
            tid = task_id_for(atlas_id, m.group(1))
            return tid if tid in pointers else None
    if ULID_RE.match(ref) and atlas_id:
        tid = task_id_for(atlas_id, ref)
        return tid if tid in pointers else None
    return None

def derived_blocked(pointers: dict, task_id: str, atlas_id: str | None = None, remote_ok: dict | None = None) -> bool:
    """Derive blocked from kind:dependency. remote_ok maps atlas:// -> status or None if unresolved."""
    p = pointers[task_id]
    for dref in dependency_paths(p):
        tid = resolve_tid(pointers, dref, atlas_id)
        if tid is None:
            # maybe remote atlas://
            if is_atlas_uri(dref):
                if remote_ok is None or dref not in remote_ok or remote_ok[dref] is None:
                    return True  # fail-closed unresolved remote
                st = remote_ok[dref]
                if st in ("open", "in_progress"):
                    return True
                continue
            continue
        t = pointers.get(tid)
        if t is None:
            return True  # fail-closed missing local
        st = t.get("task_status")
        if st in ("open", "in_progress"):
            return True
    return False

def would_cycle(pointers: dict, child: str, new_parent: str) -> bool:
    if child == new_parent:
        return True
    seen = set()
    cur = new_parent
    while cur:
        if cur == child:
            return True
        if cur in seen:
            return True
        seen.add(cur)
        p = pointers.get(cur) or {}
        cur = p.get("parent")
        if cur in (None, "null", ""):
            break
    return False

def same_atlas(a: str, b: str) -> bool:
    return atlas_of(a) == atlas_of(b) and atlas_of(a) is not None

def dual_write_set_parent(pointers: dict, child: str, parent):
    if parent is not None:
        if not is_atlas_uri(parent) or not is_atlas_uri(child):
            raise SystemExit("fail-closed: parent must be atlas:// task_id")
        if not same_atlas(child, parent):
            raise SystemExit("fail-closed: cross-Atlas parent")
        if would_cycle(pointers, child, parent):
            raise SystemExit("fail-closed: hierarchy cycle")
    old = pointers[child].get("parent")
    if old in (None, "null", ""):
        old = None
    if old and old in pointers:
        st = list(pointers[old].get("sub_tasks") or [])
        pointers[old]["sub_tasks"] = [x for x in st if x != child]
    pointers[child]["parent"] = parent
    if parent:
        if parent not in pointers:
            raise SystemExit("fail-closed: unknown parent")
        st = list(pointers[parent].get("sub_tasks") or [])
        if child not in st:
            st.append(child)
        pointers[parent]["sub_tasks"] = st
    return pointers

def repair_orphans(pointers: dict):
    for pid, p in pointers.items():
        st = list(p.get("sub_tasks") or [])
        cleaned = []
        for c in st:
            child = pointers.get(c)
            if child is None:
                continue
            if child.get("parent") == pid:
                cleaned.append(c)
        p["sub_tasks"] = cleaned
        par = p.get("parent")
        if par in (None, "null", ""):
            p["parent"] = None
            continue
        if par not in pointers:
            p["parent"] = None
            continue
        pst = list(pointers[par].get("sub_tasks") or [])
        if pid not in pst:
            pst.append(pid)
            pointers[par]["sub_tasks"] = pst
    return pointers

def is_task_pointer(registry: dict, target_ref: str) -> bool:
    meta = registry.get(target_ref)
    if meta is None:
        # v0.6 path form: <folder>/<ULID>-<name>.md, including inside a list folder.
        if is_atlas_uri(target_ref):
            _, u = parse_atlas_uri(target_ref)
            if u:
                for key, val in registry.items():
                    if isinstance(key, str) and NAMED_POINTER_RE.search(key) and f"/{u}-" in f"/{key}" and not key.endswith(".task-list.md"):
                        # filename ULID must be this ULID, not a parent list folder
                        m = NAMED_POINTER_RE.search(key)
                        if m and m.group(1) == u:
                            meta = val
                            break
        if meta is None:
            return False
    return meta.get("type") == "task" and meta.get("is_pointer") is True

def would_dependency_cycle(pointers: dict, waiter: str, blocker_ref: str, atlas_id: str | None = None) -> bool:
    blocker_id = resolve_tid(pointers, blocker_ref, atlas_id)
    if blocker_id is None:
        if is_atlas_uri(blocker_ref) and atlas_of(blocker_ref) != atlas_of(waiter):
            return False  # remote — no local cycle walk
        return False
    if blocker_id == waiter:
        return True
    seen = set()
    stack = [blocker_id]
    while stack:
        cur = stack.pop()
        if cur == waiter:
            return True
        if cur in seen:
            continue
        seen.add(cur)
        for dref in dependency_paths(pointers.get(cur) or {}):
            nid = resolve_tid(pointers, dref, atlas_id)
            if nid:
                stack.append(nid)
    return False

def dual_write_set_dependency(pointers: dict, waiter: str, blocker_ref: str, registry: dict | None = None, atlas_id: str | None = None, allow_cross: bool = True):
    if registry is not None and not is_task_pointer(registry, blocker_ref) and not (
        allow_cross and is_atlas_uri(blocker_ref) and atlas_of(blocker_ref) != atlas_of(waiter)
    ):
        # cross-atlas: registry may not have remote; allow if atlas:// different home
        if not (allow_cross and is_atlas_uri(blocker_ref) and atlas_of(blocker_ref) != atlas_of(waiter)):
            raise SystemExit("fail-closed: non-task dependency target")
    if would_dependency_cycle(pointers, waiter, blocker_ref, atlas_id):
        raise SystemExit("fail-closed: dependency cycle")
    w = pointers[waiter]
    rt = list(w.get("relates_to") or [])
    if not any(isinstance(e, dict) and e.get("kind") == "dependency" and e.get("path") == blocker_ref for e in rt):
        rt.append({"path": blocker_ref, "kind": "dependency"})
    w["relates_to"] = rt
    # same-Atlas dual-write blocks; cross-Atlas: local only
    if is_atlas_uri(blocker_ref) and atlas_of(blocker_ref) != atlas_of(waiter):
        return pointers  # no remote blocks write
    blocker_id = resolve_tid(pointers, blocker_ref, atlas_id)
    if blocker_id is None:
        raise SystemExit("fail-closed: unknown blocker")
    b = pointers[blocker_id]
    brt = list(b.get("relates_to") or [])
    if not any(isinstance(e, dict) and e.get("kind") == "blocks" and e.get("path") == waiter for e in brt):
        brt.append({"path": waiter, "kind": "blocks"})
    b["relates_to"] = brt
    return pointers

def dual_write_clear_dependency(pointers: dict, waiter: str, blocker_ref: str, atlas_id: str | None = None):
    w = pointers[waiter]
    w["relates_to"] = [
        e for e in (w.get("relates_to") or [])
        if not (isinstance(e, dict) and e.get("kind") == "dependency" and e.get("path") == blocker_ref)
    ]
    if is_atlas_uri(blocker_ref) and atlas_of(blocker_ref) != atlas_of(waiter):
        return pointers
    blocker_id = resolve_tid(pointers, blocker_ref, atlas_id)
    if blocker_id and blocker_id in pointers:
        b = pointers[blocker_id]
        b["relates_to"] = [
            e for e in (b.get("relates_to") or [])
            if not (isinstance(e, dict) and e.get("kind") == "blocks" and e.get("path") == waiter)
        ]
    return pointers

def file_safe_name(title: str, max_len: int = 48) -> str:
    s = re.sub(r"[^a-z0-9]+", "-", (title or "").lower()).strip("-")
    if not s:
        s = "item"
    return s[:max_len].strip("-") or "item"

def path_for_named(ulid: str, name: str, folder: str = "tasks") -> str:
    return f"{folder}/{ulid}-{name}.md"

def list_path(ulid: str, name: str, parent_folder: str = "tasks") -> tuple[str, str]:
    folder = f"{parent_folder}/{ulid}-{name}"
    return folder, f"{folder}/{ulid}-{name}.task-list.md"

def would_list_membership_cycle(nodes: dict, member: str, new_list_id) -> bool:
    """True when setting member.task_list = new_list_id would self-link or nest under a descendant."""
    if not new_list_id:
        return False
    if member == new_list_id:
        return True
    # Descend from member through nested task-lists; if new_list_id is reachable, cycle.
    stack = [member]
    seen = set()
    while stack:
        cur = stack.pop()
        if cur in seen:
            continue
        seen.add(cur)
        node = nodes.get(cur) or {}
        if node.get("type") != "task-list":
            continue
        for ref in list(node.get("tasks") or []):
            matches = resolve_tasks_ref(nodes, ref)
            if not matches:
                continue
            child_id = matches[0]
            if child_id == new_list_id:
                return True
            child = nodes.get(child_id) or {}
            if child.get("type") == "task-list":
                stack.append(child_id)
    return False

def dual_write_set_membership(nodes: dict, member: str, list_id, root_id=None):
    """nodes keyed by task_id; list nodes have type task-list and tasks:[]; tasks have task_list.

    Clear (list_id is None) reparents onto root before any graph mutation:
    - type task → omit task_list and append URI to root.tasks (loose on root)
    - type task-list → set task_list to root_id and append URI to root.tasks
    root_id is required for clear; validated before mutating.

    Set/change onto a list: when the member was loose (no old task_list), root_id is
    required and the loose root.tasks row is removed before the new membership is added.

    A task member whose target is the root is rejected before any mutation
    (loose tasks omit task_list). Nested task lists may still target the root.
    """
    # Validate target and cycles before any mutation (fail-closed / one-write).
    if list_id is None:
        if not root_id:
            raise SystemExit("fail-closed: clear membership requires root_id")
        if root_id not in nodes:
            raise SystemExit("fail-closed: unknown root")
        if nodes[root_id].get("type") != "task-list":
            raise SystemExit("fail-closed: root is not a task-list")
        if member == root_id:
            raise SystemExit("fail-closed: cannot clear membership of root")
    else:
        if list_id not in nodes:
            raise SystemExit("fail-closed: unknown task_list")
        if nodes[list_id].get("type") != "task-list":
            raise SystemExit("fail-closed: task_list target is not a task-list")
        member_type = (nodes.get(member) or {}).get("type")
        target_tl = nodes[list_id].get("task_list")
        target_is_root = (root_id is not None and list_id == root_id) or target_tl in (None, "null", "")
        # Loose root tasks omit task_list. Writing the root URI is a state
        # compliance_walk rejects. Reject before any membership mutation.
        if member_type == "task" and target_is_root:
            raise SystemExit("fail-closed: task membership target is root; omit task_list")
        if member_type == "task-list":
            if would_list_membership_cycle(nodes, member, list_id):
                raise SystemExit("fail-closed: cyclic list link")
    old = nodes[member].get("task_list")
    if old in (None, "null", ""):
        old = None
    # Loose→list needs root_id before mutate so the root loose row can be dropped.
    if list_id is not None and old is None:
        if not root_id:
            raise SystemExit("fail-closed: loose→list membership requires root_id")
        if root_id not in nodes:
            raise SystemExit("fail-closed: unknown root")
        if nodes[root_id].get("type") != "task-list":
            raise SystemExit("fail-closed: root is not a task-list")
    if old and old in nodes:
        lst = list(nodes[old].get("tasks") or [])
        nodes[old]["tasks"] = [x for x in lst if x != member]
    if list_id is None:
        member_type = (nodes.get(member) or {}).get("type")
        if member_type == "task-list":
            nodes[member]["task_list"] = root_id
        else:
            nodes[member]["task_list"] = None
        lst = list(nodes[root_id].get("tasks") or [])
        if member not in lst:
            lst.append(member)
        nodes[root_id]["tasks"] = lst
    else:
        if old is None:
            root_lst = list(nodes[root_id].get("tasks") or [])
            nodes[root_id]["tasks"] = [x for x in root_lst if x != member]
        nodes[member]["task_list"] = list_id
        lst = list(nodes[list_id].get("tasks") or [])
        if member not in lst:
            lst.append(member)
        nodes[list_id]["tasks"] = lst
    return nodes

def resolve_tasks_ref(nodes: dict, ref) -> list:
    """Graph keys for a tasks membership entry. Membership must be atlas:// URI."""
    if not isinstance(ref, str) or not is_atlas_uri(ref):
        raise SystemExit("fail-closed: tasks entry must be atlas:// URI")
    # Exact key plus every physical owner with the same task_id (collision surface).
    matches = []
    seen = set()
    if ref in nodes:
        matches.append(ref)
        seen.add(ref)
    for k, n in nodes.items():
        if isinstance(n, dict) and n.get("task_id") == ref and k not in seen:
            matches.append(k)
            seen.add(k)
    return matches

def reachable_ulid_owner(nodes: dict, root_id: str):
    """Map ULID -> graph key for every node reachable from the root.

    Pointer walk only. Not a store-wide discovery scan.
    Resolve the root through resolve_tasks_ref and fail when that URI has
    multiple owners before traversing. Record a dangling root reference
    even when its node cannot be loaded; only skip descending from a
    missing node.
    """
    root_owners = resolve_tasks_ref(nodes, root_id)
    if len(root_owners) > 1:
        raise SystemExit("fail-closed: ULID collision")
    owners = {}
    stack = list(root_owners) if root_owners else [root_id]
    seen = set()
    while stack:
        cur = stack.pop()
        if cur in seen:
            continue
        seen.add(cur)
        node = nodes.get(cur)
        tid = (node or {}).get("task_id") or cur
        u = None
        if isinstance(tid, str):
            u = ulid_of(tid) if is_atlas_uri(tid) else (tid if ULID_RE.match(tid) else None)
        if u is None and isinstance(cur, str) and is_atlas_uri(cur):
            u = ulid_of(cur)
        if u is not None:
            prev = owners.get(u)
            if prev is not None and prev != cur:
                raise SystemExit("fail-closed: ULID collision")
            owners[u] = cur
        if node is None:
            continue
        if node.get("type") == "task-list":
            for ref in list(node.get("tasks") or []):
                matches = resolve_tasks_ref(nodes, ref)
                if len(matches) > 1:
                    raise SystemExit("fail-closed: ULID collision")
                if matches:
                    stack.append(matches[0])
                else:
                    # dangling URI — still record it for collision checks
                    stack.append(ref)
    return owners


def ulid_taken(nodes: dict, root_id: str, ulid: str) -> bool:
    """True when the reachable graph from the root already uses this ULID."""
    try:
        owners = reachable_ulid_owner(nodes, root_id)
    except SystemExit:
        return True
    return ulid in owners

def compliance_walk(nodes: dict, root_id: str) -> None:
    """Fail if membership sides disagree, listed task is also loose on root, list-link copied tasks, list parent drifts, target type is unsupported, or a ULID collides."""
    # Same owner check as the collision walk: a second physical page that
    # declares root_id must fail before the canonical root is read.
    root_owners = resolve_tasks_ref(nodes, root_id)
    if len(root_owners) > 1:
        raise SystemExit("fail-closed: ULID collision")
    root = nodes[root_id]
    if root.get("type") != "task-list":
        raise SystemExit("fail-closed: root is not task-list")
    # Root never sets task_list (no self-reference / no parent).
    rtl = root.get("task_list")
    if rtl not in (None, "null", ""):
        raise SystemExit("fail-closed: root must omit task_list")
    root_tasks = list(root.get("tasks") or [])
    seen = set()
    seen_ulids = {}

    def note_id(ref) -> None:
        node = nodes.get(ref) or {}
        tid = node.get("task_id") or ref
        u = None
        if isinstance(tid, str):
            u = ulid_of(tid) if is_atlas_uri(tid) else (tid if ULID_RE.match(tid) else None)
        if u is None and isinstance(ref, str) and is_atlas_uri(ref):
            u = ulid_of(ref)
        if u is None:
            return
        prev = seen_ulids.get(u)
        if prev is not None and prev != ref:
            raise SystemExit("fail-closed: ULID collision")
        seen_ulids[u] = ref

    note_id(root_id)
    stack = [(root_id, ())]
    while stack:
        lid, ancestors = stack.pop()
        if lid in seen:
            continue
        seen.add(lid)
        node = nodes.get(lid)
        if not node or node.get("type") != "task-list":
            continue
        for ref in list(node.get("tasks") or []):
            matches = resolve_tasks_ref(nodes, ref)
            if len(matches) > 1:
                raise SystemExit("fail-closed: ULID collision")
            if not matches:
                raise SystemExit(f"fail-closed: dangling tasks pointer {ref}")
            owner_key = matches[0]
            child = nodes.get(owner_key)
            if child is None:
                raise SystemExit(f"fail-closed: dangling tasks pointer {ref}")
            note_id(owner_key)
            if child.get("type") == "task-list":
                # Reciprocal parent before traverse. Self-links and cycles fail closed.
                if owner_key == lid or owner_key in ancestors:
                    raise SystemExit("fail-closed: cyclic list link")
                if child.get("task_list") != lid:
                    raise SystemExit("fail-closed: membership both-sides disagree")
                # pointer only — must not duplicate child's task URIs into this list
                child_members = set(child.get("tasks") or [])
                mine = set(node.get("tasks") or [])
                overlap = child_members & (mine - {ref})
                if overlap:
                    if lid == root_id:
                        raise SystemExit("fail-closed: listed task also loose on index")
                    raise SystemExit("fail-closed: list-link copied target tasks")
                stack.append((owner_key, ancestors + (lid,)))
            elif child.get("type") == "task":
                tl = child.get("task_list")
                if lid == root_id:
                    # loose root row must omit task_list (empty forms only).
                    # task_list set to the root URI is not compliant.
                    if tl in (None, "null", ""):
                        pass
                    elif tl == root_id:
                        raise SystemExit("fail-closed: loose task must omit task_list")
                    else:
                        raise SystemExit("fail-closed: listed task also loose on index")
                else:
                    if tl != lid:
                        raise SystemExit("fail-closed: membership both-sides disagree")
                    if ref in root_tasks:
                        raise SystemExit("fail-closed: listed task also loose on index")
            else:
                raise SystemExit("fail-closed: tasks pointer target is not a task")
    # every non-root list member must not be loose
    for tid, n in nodes.items():
        if n.get("type") == "task" and n.get("task_list") not in (None, "null", ""):
            if tid in root_tasks:
                raise SystemExit("fail-closed: listed task also loose on index")
            owner = n.get("task_list")
            if owner and tid not in (nodes.get(owner) or {}).get("tasks", []):
                raise SystemExit("fail-closed: membership both-sides disagree")

def suffix_ok(path: str, typ: str, is_root_index: bool = False) -> bool:
    if typ == "task-list":
        if is_root_index:
            # Exact relative path, or slash-delimited absolute/suffixed form.
            # endswith("tasks/index.md") is rejected: it also matches mytasks/index.md.
            return path == "tasks/index.md" or path.endswith("/tasks/index.md")
        return path.endswith(".task-list.md")
    if typ == "task":
        return path.endswith(".md") and not path.endswith(".task-list.md")
    return True

PY

run_check() {
  local name="$1"
  want "$name" || return 0
  shift
  "$@"
}

# ---------------------------------------------------------------------------
# Check: package-identity (v0.5)
# ---------------------------------------------------------------------------
check_package_identity() {
  grep -qE '^name: atlas-tasks$' "$PKG_ROOT/apm.yml" || fail "apm.yml name"
  grep -qE 'version: "0\.8\.0"' "$PKG_ROOT/apm.yml" || fail "apm.yml version"
  grep -qE '^name: atlas-tasks$' "$SKILL/SKILL.md" || fail "SKILL name"
  grep -qE 'version: "0\.8\.0"' "$SKILL/SKILL.md" || fail "SKILL version"
  [[ -d "$SKILL/contributions/atlas-tasks" ]] || fail "missing contributions/atlas-tasks"
  [[ ! -d "$SKILL/contributions/atlas-todo" ]] || fail "legacy contributions/atlas-todo present"
  [[ -f "$SKILL/references/paths/migrate.md" ]] || fail "missing migrate path"
  [[ -f "$SKILL/references/scenarios/atlas-tasks-adversarial-v3.yaml" ]] || fail "missing atlas-tasks adversarial v3"
  [[ -f "$SKILL/references/scenarios/atlas-tasks-adversarial-v4.yaml" ]] || fail "missing atlas-tasks adversarial v4"
  grep -q 'atlas://' "$SKILL/SKILL.md" || fail "SKILL missing atlas:// identity"
  grep -qE 'tasks/<ULID>|<ULID>-<file-safe-name>' "$SKILL/SKILL.md" || fail "SKILL missing physical path grammar"
  if grep -RE 'todo_id:|todo_status:' "$README_CONTRIB" "$SKILL/references/paths/add.md" 2>/dev/null \
    | grep -vE 'todo_id →|todo_status →|Never write .todo_|legacy|migrate|Hard cut|no .todo_'; then
    fail "contract samples still use todo_id/todo_status"
  fi
  echo "atlas-tasks 0.6.3"
  grep -q 'type: task-list' "$SKILL/SKILL.md" || fail "SKILL missing task-list"
  grep -q 'task_list' "$SKILL/SKILL.md" || fail "SKILL missing task_list field"
  grep -q '<ULID>-<file-safe-name>' "$SKILL/SKILL.md" || fail "SKILL missing ULID-plus-name filename"
  grep -qE 'caller-supplied|attempted duplicate' "$SKILL/references/paths/add.md" \
    || fail "add path must fail closed on supplied task_id collision (no remint)"
  grep -qE 'caller-supplied|attempted duplicate' "$SKILL/SKILL.md" \
    || fail "SKILL must fail closed on supplied task_id collision (no remint)"
  grep -qE 'always omits|root index \*\*always omits\*\*|root \*\*omits\*\* .task_list|never a self-reference' \
    "$SKILL/references/paths/add.md" "$README_CONTRIB" \
    || fail "docs must require root to omit task_list (no self-reference)"
  if grep -nE 'self-reference per skill|may omit or self-reference' "$README_CONTRIB" "$SKILL/references/paths/add.md" 2>/dev/null; then
    fail "docs still allow root task_list self-reference"
  fi
  pass "package-identity: atlas-tasks 0.8.0"
}
run_check package-identity check_package_identity

check_recall_alias() {
  grep '^description:' "$SKILL/SKILL.md" \
    | grep -Fq -- 'recall tasks, query tasks (deprecated alias of recall)' \
    || fail "SKILL description must trigger on query tasks as a deprecated alias of recall"
  grep -Fq -- '- **list** / recall → `references/paths/list.md`' "$SKILL/SKILL.md" \
    || fail "SKILL must route list / recall to references/paths/list.md"
  grep -Fq -- '- `query` (deprecated alias) → same as **list** / recall' "$SKILL/SKILL.md" \
    || fail "SKILL must keep query as a deprecated alias for list / recall"
  pass "recall-alias: recall routes to list and query remains deprecated alias"
}
run_check recall-alias check_recall_alias

check_list_folder_index() {
  [[ -x "$SKILL/scripts/list-folder-index.py" ]] || fail "scripts/list-folder-index.py missing or not executable"
  grep -Fq '23. **List folder index (v0.7):**' "$SKILL/SKILL.md" || fail "SKILL pin 23 missing"
  grep -Fq 'Checklist E' "$SKILL/references/paths/migrate.md" || fail "migrate Checklist E missing"
  grep -Fq 'list-folder-index.py' "$SKILL/references/paths/add.md" || fail "add must refresh list-folder index"
  grep -Fq 'list-folder-index.py' "$SKILL/references/paths/update.md" || fail "update must refresh list-folder index"
  pass "list-folder-index: script + pin 23 + add/update/migrate docs"
  # Review fixes: YAML quoting, flow/unindented sequences, unresolved pointers, bad --list.
  local F; F="$(mktemp -d)"
  local A="atlas://example.test/s/atlas/tasks"
  local UR="01J8E3KBR8V6Z2B9T0V3V4Y5A0" UL="01J8E3KBR8V6Z2B9T0V3V4Y5A1" UT="01J8E3KBR8V6Z2B9T0V3V4Y5A2"
  local UL2="01J8E3KBR8V6Z2B9T0V3V4Y5A3" UT2="01J8E3KBR8V6Z2B9T0V3V4Y5A4"
  mkdir -p "$F/tasks/${UL}-logs" "$F/tasks/${UL2}-two"
  printf -- "---\ntype: task-list\ntitle: Tasks index\ntask_id: %s/%s\ntasks: [%s/%s, %s/%s]\n---\n" "$A" "$UR" "$A" "$UL" "$A" "$UL2" > "$F/tasks/index.md"
  printf -- "---\ntype: task-list\ntitle: 'Check C:\\\\logs and it''s \"done\"'\ntask_id: %s/%s\ntask_list: %s/%s\ntasks:\n- %s/%s\n---\n" "$A" "$UL" "$A" "$UR" "$A" "$UT" > "$F/tasks/${UL}-logs/${UL}-logs.task-list.md"
  printf -- "---\ntype: task\ntitle: T\ntask_id: %s/%s\n---\n" "$A" "$UT" > "$F/tasks/${UL}-logs/${UT}-t.md"
  printf -- "---\ntype: task-list\ntitle: Two\ntask_id: %s/%s\ntask_list: %s/%s\ntasks: [%s/%s]\n---\n" "$A" "$UL2" "$A" "$UR" "$A" "$UT2" > "$F/tasks/${UL2}-two/${UL2}-two.task-list.md"
  printf -- "---\ntype: task\ntitle: T2\ntask_id: %s/%s\n---\n" "$A" "$UT2" > "$F/tasks/${UL2}-two/${UT2}-t2.md"
  python3 "$SKILL/scripts/list-folder-index.py" --root "$F" >/dev/null || fail "list-folder-index: flow/unindented sequences must resolve"
  [[ -f "$F/tasks/${UL2}-two/index.md" ]] || fail "list-folder-index: flow-sequence list not reached"
  grep -Fq "\`${UT}\`" "$F/tasks/${UL}-logs/index.md" || fail "list-folder-index: unindented block sequence member missing"
  python3 - "$F/tasks/${UL}-logs/index.md" <<'PY' || fail "list-folder-index: generated frontmatter must be valid YAML keeping backslashes"
import re,sys,yaml
t=open(sys.argv[1]).read(); m=re.match(r"^---\n(.*?)\n---\n",t,re.S)
fm=yaml.safe_load(m.group(1)); assert fm["title"]=="Index: Check C:\\logs and it's \"done\"", fm["title"]; assert "type" not in fm
PY
  if python3 "$SKILL/scripts/list-folder-index.py" --root "$F" --list 01J8E3KBR8V6Z2B9T0V3V4Y5ZZ >/dev/null 2>&1; then fail "list-folder-index: unreachable --list must exit nonzero"; fi
  printf -- "---\ntype: task-list\ntitle: Tasks index\ntask_id: %s/%s\ntasks: [%s/01J8E3KBR8V6Z2B9T0V3V4Y5ZY]\n---\n" "$A" "$UR" "$A" > "$F/tasks/index.md"
  if python3 "$SKILL/scripts/list-folder-index.py" --root "$F" --dry-run >/dev/null 2>&1; then fail "list-folder-index: unresolved root pointer must exit nonzero"; fi
  # Containment: a symlinked list folder or index.md must never redirect writes outside --root.
  local O; O="$(mktemp -d)"
  printf -- "---\ntype: task-list\ntitle: Tasks index\ntask_id: %s/%s\ntasks: [%s/%s]\n---\n" "$A" "$UR" "$A" "$UL" > "$F/tasks/index.md"
  mkdir -p "$O/${UL}-logs"; cp "$F/tasks/${UL}-logs/"*.md "$O/${UL}-logs/"; rm -f "$O/${UL}-logs/index.md"
  mv "$F/tasks/${UL}-logs" "$F/tasks/moved-away"; ln -s "$O/${UL}-logs" "$F/tasks/${UL}-logs"
  if python3 "$SKILL/scripts/list-folder-index.py" --root "$F" >/dev/null 2>&1; then fail "list-folder-index: symlinked list folder must fail closed"; fi
  [[ ! -e "$O/${UL}-logs/index.md" ]] || fail "list-folder-index wrote outside --root via symlinked folder"
  rm "$F/tasks/${UL}-logs"; mv "$F/tasks/moved-away" "$F/tasks/${UL}-logs"
  mv "$F/tasks/${UL}-logs/index.md" "$O/outside-index.md"; ln -s "$O/outside-index.md" "$F/tasks/${UL}-logs/index.md"
  before="$(cat "$O/outside-index.md")"; echo "# changed" >> "$F/tasks/${UL}-logs/${UL}-logs.task-list.md"
  if python3 "$SKILL/scripts/list-folder-index.py" --root "$F" >/dev/null 2>&1; then fail "list-folder-index: symlinked index.md must fail closed"; fi
  [[ "$(cat "$O/outside-index.md")" == "$before" ]] || fail "list-folder-index wrote through index.md symlink"
  rm -rf "$O"
  rm -rf "$F"
  pass "list-folder-index: YAML-safe quoting, flow/unindented sequences, unresolved pointer and bad --list fail closed"
}
run_check list-folder-index check_list_folder_index

check_tasks_writer() {
  local tw="$SKILL/scripts/tasks.py"
  [[ -f "$tw" && -x "$tw" ]] || fail "scripts/tasks.py missing or not executable"
  grep -Fq '24. **Writer script (v0.8):**' "$SKILL/SKILL.md" || fail "SKILL pin 24 missing"
  grep -Fq 'scripts/tasks.py' "$SKILL/references/paths/add.md" || fail "add.md must mention tasks.py"
  grep -Fq 'scripts/tasks.py' "$SKILL/references/paths/update.md" || fail "update.md must mention tasks.py"
  grep -Fq 'scripts/tasks.py' "$SKILL/references/paths/complete.md" || fail "complete.md must mention tasks.py"
  if grep -q 'subprocess' "$tw"; then fail "tasks.py must not use subprocess"; fi
  if grep -q 'os.system' "$tw"; then fail "tasks.py must not use os.system"; fi
  if grep -q 'git ' "$tw"; then fail "tasks.py must not invoke git"; fi
  pass "tasks-writer: script + pin 24 + path docs; no subprocess, os.system, or git"
}
run_check tasks-writer check_tasks_writer

check_no_mandatory_notes_or_vault_tool() {
  python3 - "$SKILL" <<'PY' || fail "no-mandatory-notes-or-vault-tool"
import re
import sys
from pathlib import Path

root = Path(sys.argv[1])
files = [root / "SKILL.md", root / "README.md", root / "apm.yml"]
for directory in ("references", "contributions", "scripts"):
    files.extend(
        path for path in (root / directory).rglob("*")
        if path.is_file() and path.name != "CHANGELOG.md"
        and path != root / "scripts" / "smoke-check.sh"
    )

issues = []
for path in files:
    text = path.read_text(encoding="utf-8")
    for number, line in enumerate(text.splitlines(), 1):
        if re.search(r"apple-notes", line, re.IGNORECASE):
            issues.append(f"{path.relative_to(root)}:{number}: apple-notes dependency/reference")
        if re.search(r"\bop\s+(?:read|item)\b|op://", line, re.IGNORECASE):
            issues.append(f"{path.relative_to(root)}:{number}: 1Password command")
        for match in re.finditer(r"apple.?notes|1password", line, re.IGNORECASE):
            if not re.search(r"e\.g\.[^).;:!?()]*$", line[:match.start()]):
                issues.append(f"{path.relative_to(root)}:{number}: Apple Notes/1Password mention needs e.g.")

if issues:
    raise SystemExit("\n".join(issues))
print("no mandatory Apple Notes or 1Password tooling")
PY
  pass "no-mandatory-notes-or-vault-tool: no required Notes/vault tooling"
}
run_check no-mandatory-notes-or-vault-tool check_no_mandatory_notes_or_vault_tool

check_overlay_claim() {
  python3 - <<PY || fail "overlay-claim"
import json,sys
o=json.load(open("$OVERLAY"))
cf = o.get("claimed_folders") or []
assert cf == ["tasks"] or ("tasks" in cf and "todo" not in cf), "claimed_folders"
bt=(o.get("templates") or {}).get("by_type") or {}
assert "task" not in bt, "must not declare templates.by_type.task"
assert o.get("contribution_id") == "atlas-tasks", "contribution_id"
print("claimed_folders=[tasks]")
PY
  pass "overlay-claim: claimed_folders=[tasks], no templates.by_type.task"
}
run_check overlay-claim check_overlay_claim

# Atlas SCHEMA 2.0 stores validate overlays against contribution-v1
# (unevaluatedProperties: false): any other root key fails `schema install`.
check_overlay_root_keys() {
  python3 - <<PY || fail "overlay-root-keys"
import json
o = json.load(open("$OVERLAY"))
allowed = {"contribution_id", "claimed_folders", "templates", "types", "bindings", "presets"}
extra = sorted(set(o) - allowed)
assert not extra, f"overlay root keys outside the Atlas contribution contract: {extra}"
print("root keys:", sorted(o))
PY
  grep -q 'only Atlas contract keys' "$README_CONTRIB" \
    || fail "contribution README must state the overlay carries only Atlas contract keys"
  pass "overlay-root-keys: overlay root keys within {contribution_id, claimed_folders, templates, types, bindings, presets}"
}
run_check overlay-root-keys check_overlay_root_keys

check_no_depends_on_field() {
  if grep -nE '^\| `depends_on` \|' "$README_CONTRIB" 2>/dev/null; then
    fail "README still lists depends_on as a contract field"
  fi
  if grep -nE '^depends_on:' "$SKILL/references/paths/add.md" 2>/dev/null; then
    fail "add path sample still writes depends_on"
  fi
  grep -qE 'No `depends_on`|No \*\*`depends_on`\*\*|remove.*depends_on|never write.*depends_on|Never write.*depends_on|do not write or require `depends_on`|Do not write or require `depends_on`' \
    "$SKILL/SKILL.md" || fail "SKILL must forbid depends_on"
  grep -q 'kind: dependency' "$SKILL/SKILL.md" || fail "SKILL missing kind: dependency"
  grep -q 'kind: blocks' "$SKILL/SKILL.md" || fail "SKILL missing kind: blocks"
  grep -q 'kind: dependency' "$README_CONTRIB" || fail "README missing kind: dependency"
  echo "skill/docs do not require depends_on"
  pass "no-depends_on-field: skill/docs do not require depends_on"
}
run_check no-depends_on-field check_no_depends_on_field

check_no_blocked_status() {
  grep -qE 'no `task_status: blocked`|Do not invent `task_status: blocked`|never invent `task_status: blocked`|nor `task_status: blocked`' \
    "$SKILL/SKILL.md" "$README_CONTRIB" || fail "docs must forbid task_status: blocked"
  python3 - <<'PY' || fail "no-blocked-status enum"
ALLOWED = {"open", "in_progress", "done", "cancelled"}
for bad in ("blocked", "duplicate", "wip"):
    if bad in ALLOWED:
        raise SystemExit(f"bad status allowed: {bad}")
    assert bad not in ALLOWED
print("reject task_status:blocked; derived only")
PY
  if grep -RnE 'Set `task_status: blocked`|task_status: blocked$' "$SKILL/references/paths" "$SKILL/SKILL.md" "$README_CONTRIB" 2>/dev/null | grep -vE 'no |not |never |reject|forbid|including|invent|nor '; then
    fail "docs advertise setting task_status: blocked"
  fi
  pass "no-blocked-status: reject task_status:blocked; derived only"
}
run_check no-blocked-status check_no_blocked_status

check_assignees_list() {
  grep -qE 'Never singular `assignee`|never singular `assignee`|Never.*singular `assignee`' "$SKILL/SKILL.md" \
    || fail "SKILL must forbid singular assignee"
  grep -q 'assignees' "$README_CONTRIB" || fail "README missing assignees"
  grep -qE 'Singular `assignee`|singular `assignee`' "$SKILL/references/paths/add.md" \
    || fail "add path must reject singular assignee"
  grep -qE 'Singular `assignee`|singular `assignee`' "$SKILL/references/paths/update.md" \
    || fail "update path must reject singular assignee"
  python3 - <<'PY' || fail "assignees-list sim"
fm = {"assignees": ["alice", "bob"]}
assert "assignee" not in fm
bad = {"assignee": "alice"}
if "assignee" in bad and "assignees" not in bad:
    print("reject singular assignee; assignees list only")
else:
    raise SystemExit("expected singular reject path")
PY
  pass "assignees-list: reject singular assignee; assignees list only"
}
run_check assignees-list check_assignees_list

check_frontmatter_keys() {
  README_CONTRIB="$README_CONTRIB" python3 - <<'PY' || fail "frontmatter-keys"
import os
text = open(os.environ["README_CONTRIB"]).read()
for key in ("assignees", "parent", "sub_tasks", "relates_to", "task_status", "task_id", "body_path", "related_node", "task_list"):
    assert key in text, f"README missing {key}"
assert "`tasks`" in text or "| `tasks` |" in text or "list `tasks`" in text or "tasks` |" in text or "YAML list of member" in text, "README missing list tasks field"
assert "task-list" in text, "README missing task-list type"
for bad in ("| `todo_id` |", "| `todo_status` |", "| `depends_on` |", "| `display_slug` |"):
    assert bad not in text, f"README still documents {bad}"
fm = {
  "type": "task", "title": "T", "created": "2026-10-01",
  "task_id": "atlas://github.com/example/demo/tasks/01J8E3K7M4Q2V8X5N6P9R0T1YZ",
  "task_status": "open",
  "body_path": "knowledge/x.md", "related_node": "knowledge/y.md",
  "assignees": ["alice"], "parent": None, "sub_tasks": [],
  "relates_to": [{"path": "atlas://github.com/example/demo/tasks/01J8E3K8N5R3W9Y6P7Q0S1V2A0", "kind": "dependency"}],
}
for k in ("assignees", "parent", "sub_tasks", "relates_to", "task_status", "task_id", "body_path", "related_node"):
    assert k in fm
assert "assignee" not in fm
assert "blocked_by" not in fm
assert "blocked" not in fm
assert "depends_on" not in fm
assert "display_slug" not in fm
assert "todo_id" not in fm
assert fm["task_id"].startswith("atlas://")
print("frontmatter keys ok; atlas:// task_id; no depends_on/display_slug")
PY
  pass "frontmatter-keys: atlas:// task_id + assignees/parent/sub_tasks/relates_to; no depends_on/display_slug/todo_*"
}
run_check frontmatter-keys check_frontmatter_keys

check_status_enum() {
  python3 - <<'PY' || fail "status-enum"
ALLOWED = {"open", "in_progress", "done", "cancelled"}
for ok in ALLOWED:
    assert ok in ALLOWED
for bad in ("blocked", "duplicate", "todo", "wip", "closed"):
    assert bad not in ALLOWED, bad
print("status enum ok")
PY
  grep -qE 'open.*in_progress.*done.*cancelled|open \`\|` in_progress' "$README_CONTRIB" \
    || grep -q 'in_progress' "$README_CONTRIB" || fail "README missing in_progress in enum"
  pass "status-enum: open|in_progress|done|cancelled only"
}
run_check status-enum check_status_enum

# ---------------------------------------------------------------------------
# v0.5 identity checks
# ---------------------------------------------------------------------------
check_task_id_atlas_uri() {
  grep -qE 'task_id` \*\*is\*\*|task_id is the full|`task_id` is the full|task_id` \*\*is\*\* `atlas://' "$SKILL/SKILL.md" \
    || grep -q 'atlas://<atlas_id>/tasks/<ULID>' "$SKILL/SKILL.md" || fail "SKILL missing composite task_id pin"
  python3 - <<PY || fail "task-id-atlas-uri"
exec(open("$HELPERS").read())
aid = "github.com/example/demo"
uid = "01J8E3K7M4Q2V8X5N6P9R0T1YZ"
tid = task_id_for(aid, uid)
assert is_atlas_uri(tid), tid
assert ulid_of(tid) == uid
assert atlas_of(tid) == aid
root_path = path_for(uid, "demo-task")
assert root_path == f"tasks/{uid}-demo-task.md"
list_uid = "01J8E3K8N5R3W9Y6P7Q0S1V2A0"
nested = path_for(uid, "pack-bags", folder=f"tasks/{list_uid}-trip")
assert nested == f"tasks/{list_uid}-trip/{uid}-pack-bags.md"
pointers = {tid: {"task_id": tid, "task_status": "open", "relates_to": []}}
assert resolve_tid(pointers, root_path, aid) == tid
assert resolve_tid(pointers, nested, aid) == tid
assert resolve_tid(pointers, f"tasks/{uid}.md", aid) is None
assert reject_kebab("ship-widget") is True
assert reject_kebab(tid) is False
print("task_id atlas:// composite ok; ULID-plus-name paths resolve, ULID-only path does not")
PY
  pass "task-id-atlas-uri: composite atlas://…/ULID"
}
run_check task-id-atlas-uri check_task_id_atlas_uri

check_physical_path_ulid() {
  grep -q '<ULID>-<file-safe-name>' "$SKILL/SKILL.md" || fail "SKILL missing ULID-plus-name filename shape"
  grep -qE 'tasks/<ULID>-<file-safe-name>|ULID>-<file-safe-name>' "$SKILL/references/paths/add.md" \
    || grep -q 'file-safe-name' "$SKILL/references/paths/add.md" || fail "add path missing ULID-plus-name"
  if grep -nE 'tasks/tasks/<task_id>|tasks/tasks/<kebab>' "$SKILL/references/paths/add.md" 2>/dev/null; then
    fail "add path still uses nested tasks/tasks/<kebab>"
  fi
  # ULID-only is no longer the write shape
  if grep -nE 'Write \*\*task pointer\*\* at `tasks/<ULID>\.md`' "$SKILL/references/paths/add.md" 2>/dev/null; then
    fail "add path still writes ULID-only filenames"
  fi
  echo "physical path tasks/<ULID>-<file-safe-name>.md"
  pass "physical-path-ulid: tasks/<ULID>-<file-safe-name>.md"
}
run_check physical-path-ulid check_physical_path_ulid

check_no_kebab_id() {
  grep -qE 'no kebab|No kebab|do not accept.*kebab|Do not.*kebab `task_id`|Hard cut \(v0\.5\)' "$SKILL/SKILL.md" \
    || fail "SKILL must hard-cut kebab task_id"
  grep -qE 'display_slug' "$SKILL/SKILL.md" || fail "SKILL must mention no display_slug"
  grep -qE 'No dual-read|no dual-read|Do not accept.*kebab' "$SKILL/references/paths/migrate.md" \
    || fail "migrate must say no dual-read"
  python3 - <<PY || fail "no-kebab-id"
exec(open("$HELPERS").read())
assert reject_kebab("demo-task") is True
assert reject_kebab("parent-a") is True
assert reject_kebab("atlas://github.com/x/y/tasks/01J8E3K7M4Q2V8X5N6P9R0T1YZ") is False
print("reject kebab task_id; no dual-read")
PY
  pass "no-kebab-id: reject kebab task_id; no dual-read"
}
run_check no-kebab-id check_no_kebab_id

check_human_facing_ulid() {
  grep -qE 'title \+ ULID|title + ULID|\*\*title \+ ULID\*\*' "$SKILL/SKILL.md" \
    || fail "SKILL missing human-facing title+ULID"
  grep -qE 'no kebab `display_slug`|No kebab `display_slug`|no `display_slug`' "$SKILL/SKILL.md" \
    || fail "SKILL must forbid display_slug"
  echo "human-facing title + ULID"
  pass "human-facing-ulid: title + ULID; no display_slug"
}
run_check human-facing-ulid check_human_facing_ulid

check_cross_atlas_dependency() {
  grep -qE 'may cross|cross Atlases|cross-Atlas' "$SKILL/SKILL.md" || fail "SKILL missing cross-Atlas dependency allow"
  python3 - <<PY || fail "cross-atlas-dependency"
exec(open("$HELPERS").read())
local_a = "github.com/example/a"
local_b = "github.com/example/b"
u1 = "01J8E3K7M4Q2V8X5N6P9R0T1YZ"
u2 = "01J8E3K8N5R3W9Y6P7Q0S1V2A0"
waiter = task_id_for(local_a, u1)
remote = task_id_for(local_b, u2)
pointers = {
  waiter: {"task_id": waiter, "task_status": "open", "parent": None, "sub_tasks": [], "relates_to": []},
}
registry = {path_for(u1, "local-task"): {"type": "task", "is_pointer": True}}
dual_write_set_dependency(pointers, waiter, remote, registry, atlas_id=local_a, allow_cross=True)
assert any(e.get("path") == remote and e.get("kind") == "dependency" for e in pointers[waiter]["relates_to"])
# no remote blocks invented locally
assert len(pointers) == 1
print("cross-Atlas dependency edge allowed (local only)")
PY
  pass "cross-atlas-dependency: remote atlas:// dependency allowed; no remote blocks write"
}
run_check cross-atlas-dependency check_cross_atlas_dependency

check_same_atlas_parent() {
  python3 - <<PY || fail "same-atlas-parent"
exec(open("$HELPERS").read())
a = "github.com/example/a"
b = "github.com/example/b"
u1 = "01J8E3K7M4Q2V8X5N6P9R0T1YZ"
u2 = "01J8E3K8N5R3W9Y6P7Q0S1V2A0"
child = task_id_for(a, u1)
foreign_parent = task_id_for(b, u2)
local_parent = task_id_for(a, u2)
pointers = {
  child: {"task_id": child, "task_status": "open", "parent": None, "sub_tasks": [], "relates_to": []},
  local_parent: {"task_id": local_parent, "task_status": "open", "parent": None, "sub_tasks": [], "relates_to": []},
}
try:
    dual_write_set_parent(pointers, child, foreign_parent)
    raise SystemExit("should reject cross-Atlas parent")
except SystemExit as e:
    if "cross-Atlas parent" not in str(e):
        raise
dual_write_set_parent(pointers, child, local_parent)
assert pointers[child]["parent"] == local_parent
assert child in pointers[local_parent]["sub_tasks"]
print("fail-closed: cross-Atlas parent")
PY
  pass "same-atlas-parent: fail-closed: cross-Atlas parent"
}
run_check same-atlas-parent check_same_atlas_parent

check_fail_closed_remote() {
  python3 - <<PY || fail "fail-closed-remote"
exec(open("$HELPERS").read())
a = "github.com/example/a"
b = "github.com/example/b"
u1 = "01J8E3K7M4Q2V8X5N6P9R0T1YZ"
u2 = "01J8E3K8N5R3W9Y6P7Q0S1V2A0"
waiter = task_id_for(a, u1)
remote = task_id_for(b, u2)
pointers = {
  waiter: {"task_id": waiter, "task_status": "open", "parent": None, "sub_tasks": [], "relates_to": [
    {"path": remote, "kind": "dependency"}
  ]},
}
# unresolved remote → blocked
assert derived_blocked(pointers, waiter, atlas_id=a, remote_ok={}) is True
assert derived_blocked(pointers, waiter, atlas_id=a, remote_ok={remote: None}) is True
# remote open → blocked
assert derived_blocked(pointers, waiter, atlas_id=a, remote_ok={remote: "open"}) is True
# remote done → not blocked
assert derived_blocked(pointers, waiter, atlas_id=a, remote_ok={remote: "done"}) is False
print("fail-closed: unresolved remote dependency → blocked")
PY
  pass "fail-closed-remote: unresolved remote dependency → blocked"
}
run_check fail-closed-remote check_fail_closed_remote

# ---------------------------------------------------------------------------
# Hierarchy relation simulation checks
# ---------------------------------------------------------------------------
check_dual_write() {
  python3 - <<PY || fail "dual-write"
exec(open("$HELPERS").read())
a = "github.com/example/demo"
p = task_id_for(a, "01J8E3K7M4Q2V8X5N6P9R0T1YZ")
c = task_id_for(a, "01J8E3K8N5R3W9Y6P7Q0S1V2A0")
pointers = {
  p: {"task_id": p, "task_status": "open", "parent": None, "sub_tasks": [], "relates_to": []},
  c: {"task_id": c, "task_status": "open", "parent": None, "sub_tasks": [], "relates_to": []},
}
dual_write_set_parent(pointers, c, p)
assert pointers[c]["parent"] == p
assert c in pointers[p]["sub_tasks"]
dual_write_set_parent(pointers, c, None)
assert pointers[c]["parent"] is None
assert c not in pointers[p]["sub_tasks"]
print("dual-write sync ok")
PY
  pass "dual-write: parent/sub_tasks both ends match after set/clear"
}
run_check dual-write check_dual_write

check_cycle_reject() {
  python3 - <<PY || fail "cycle-reject"
exec(open("$HELPERS").read())
a = "github.com/example/demo"
ta = task_id_for(a, "01J8E3K7M4Q2V8X5N6P9R0T1YZ")
tb = task_id_for(a, "01J8E3K8N5R3W9Y6P7Q0S1V2A0")
pointers = {
  ta: {"task_id": ta, "task_status": "open", "parent": None, "sub_tasks": [tb], "relates_to": []},
  tb: {"task_id": tb, "task_status": "open", "parent": ta, "sub_tasks": [], "relates_to": []},
}
try:
    dual_write_set_parent(pointers, ta, tb)
    raise SystemExit("should have failed closed on cycle")
except SystemExit as e:
    if "hierarchy cycle" not in str(e):
        raise
print("fail-closed: hierarchy cycle")
assert pointers[ta]["parent"] is None
assert pointers[tb]["parent"] == ta
PY
  pass "cycle-reject: fail-closed: hierarchy cycle"
}
run_check cycle-reject check_cycle_reject

check_orphan_sub_tasks() {
  python3 - <<PY || fail "orphan-sub-tasks"
exec(open("$HELPERS").read())
a = "github.com/example/demo"
p = task_id_for(a, "01J8E3K7M4Q2V8X5N6P9R0T1YZ")
c = task_id_for(a, "01J8E3K8N5R3W9Y6P7Q0S1V2A0")
ghost = task_id_for(a, "01J8E3K9P6S4X0Z7Q8R1T2W3B1")
pointers = {
  p: {"task_id": p, "task_status": "open", "parent": None, "sub_tasks": [c, ghost], "relates_to": []},
  c: {"task_id": c, "task_status": "open", "parent": None, "sub_tasks": [], "relates_to": []},
}
repair_orphans(pointers)
assert ghost not in pointers[p]["sub_tasks"]
assert c not in pointers[p]["sub_tasks"]
pointers[c]["parent"] = p
pointers[p]["sub_tasks"] = [c]
dual_write_set_parent(pointers, c, None)
assert pointers[p]["sub_tasks"] == []
assert pointers[c]["parent"] is None
print("fail-closed-or-repaired: orphan sub_tasks")
PY
  pass "orphan-sub-tasks: fail-closed-or-repaired: orphan sub_tasks"
}
run_check orphan-sub-tasks check_orphan_sub_tasks

# ---------------------------------------------------------------------------
# Dependency edge checks
# ---------------------------------------------------------------------------
check_dual_write_blocks() {
  python3 - <<PY || fail "dual-write-blocks"
exec(open("$HELPERS").read())
a = "github.com/example/demo"
u_block = "01J8E3K7M4Q2V8X5N6P9R0T1YZ"
u_wait = "01J8E3K8N5R3W9Y6P7Q0S1V2A0"
u_list = "01J8E3K9P6S4X0Z7Q8R1T2W3B1"
blocker = task_id_for(a, u_block)
waiter = task_id_for(a, u_wait)
blocker_path = path_for(u_block, "pack-bags", folder=f"tasks/{u_list}-trip")
waiter_path = path_for(u_wait, "book-hotel")
assert blocker_path == f"tasks/{u_list}-trip/{u_block}-pack-bags.md"
assert waiter_path == f"tasks/{u_wait}-book-hotel.md"
pointers = {
  blocker: {"task_id": blocker, "task_status": "open", "parent": None, "sub_tasks": [], "relates_to": []},
  waiter: {"task_id": waiter, "task_status": "open", "parent": None, "sub_tasks": [], "relates_to": []},
}
assert resolve_tid(pointers, blocker_path, a) == blocker
assert resolve_tid(pointers, waiter_path, a) == waiter
assert resolve_tid(pointers, f"tasks/{u_block}.md", a) is None
registry = {
  blocker_path: {"type": "task", "is_pointer": True},
  waiter_path: {"type": "task", "is_pointer": True},
}
assert is_task_pointer(registry, blocker_path)
assert is_task_pointer(registry, blocker)
dual_write_set_dependency(pointers, waiter, blocker_path, registry, atlas_id=a)
assert any(e.get("kind") == "dependency" and e.get("path") == blocker_path for e in pointers[waiter]["relates_to"])
assert any(e.get("kind") == "blocks" and e.get("path") == waiter for e in pointers[blocker]["relates_to"])
assert derived_blocked(pointers, waiter, atlas_id=a) is True
print("blocker gains kind:blocks from ULID-plus-name path inside a list folder")
dual_write_clear_dependency(pointers, waiter, blocker_path, atlas_id=a)
assert dependency_paths(pointers[waiter]) == []
assert blocks_paths(pointers[blocker]) == []
print("dual-write clear ok")
PY
  pass "dual-write-blocks: blocker gains kind:blocks when waiter gains dependency"
}
run_check dual-write-blocks check_dual_write_blocks

check_non_task_dependency() {
  python3 - <<PY || fail "non-task-dependency"
exec(open("$HELPERS").read())
a = "github.com/example/demo"
waiter = task_id_for(a, "01J8E3K8N5R3W9Y6P7Q0S1V2A0")
pointers = {
  waiter: {"task_id": waiter, "task_status": "open", "parent": None, "sub_tasks": [], "relates_to": []},
}
registry = {
  path_for(ulid_of(waiter), "book-hotel"): {"type": "task", "is_pointer": True},
  waiter: {"type": "task", "is_pointer": True},
  "knowledge/demo/note.md": {"type": "document", "is_pointer": False},
  "shops/acme.md": {"type": "shop", "is_pointer": False},
}
for bad in ("knowledge/demo/note.md", "shops/acme.md", "tasks/01J8E3K7M4Q2V8X5N6P9R0T1YZ.md", "tasks/01J8E3K9P6S4X0Z7Q8R1T2W3B1-trip/01J8E3K9P6S4X0Z7Q8R1T2W3B1-trip.task-list.md"):
    try:
        dual_write_set_dependency(pointers, waiter, bad, registry, atlas_id=a)
        raise SystemExit(f"should reject {bad}")
    except SystemExit as e:
        if "fail-closed" not in str(e):
            raise
print("fail-closed: non-task dependency target")
PY
  pass "non-task-dependency: fail-closed: non-task dependency target"
}
run_check non-task-dependency check_non_task_dependency

check_blocked_from_dependency() {
  python3 - <<PY || fail "blocked-from-dependency"
exec(open("$HELPERS").read())
a = "github.com/example/demo"
dep = task_id_for(a, "01J8E3K7M4Q2V8X5N6P9R0T1YZ")
work = task_id_for(a, "01J8E3K8N5R3W9Y6P7Q0S1V2A0")
pointers = {
  dep: {"task_id": dep, "task_status": "open", "parent": None, "sub_tasks": [], "relates_to": [
    {"path": work, "kind": "blocks"}
  ]},
  work: {"task_id": work, "task_status": "open", "parent": None, "sub_tasks": [], "relates_to": [
    {"path": dep, "kind": "dependency"}
  ]},
}
assert derived_blocked(pointers, work, atlas_id=a) is True
pointers[dep]["task_status"] = "in_progress"
assert derived_blocked(pointers, work, atlas_id=a) is True
pointers[dep]["task_status"] = "done"
assert derived_blocked(pointers, work, atlas_id=a) is False
u_list = "01J8E3K9P6S4X0Z7Q8R1T2W3B1"
nested_dep = path_for(ulid_of(dep), "hold-seats", folder=f"tasks/{u_list}-trip")
assert resolve_tid(pointers, nested_dep, a) == dep
pointers[dep]["task_status"] = "open"
pointers[work]["relates_to"] = [{"path": nested_dep, "kind": "dependency"}]
assert derived_blocked(pointers, work, atlas_id=a) is True
assert resolve_tid(pointers, f"tasks/{ulid_of(dep)}.md", a) is None
assert "depends_on" not in pointers[work]
print("blocked iff any kind:dependency target open|in_progress")
PY
  pass "blocked-from-dependency: blocked iff any kind:dependency target open|in_progress"
}
run_check blocked-from-dependency check_blocked_from_dependency

check_dependency_terminal() {
  python3 - <<PY || fail "dependency-terminal"
exec(open("$HELPERS").read())
a = "github.com/example/demo"
dep = task_id_for(a, "01J8E3K7M4Q2V8X5N6P9R0T1YZ")
work = task_id_for(a, "01J8E3K8N5R3W9Y6P7Q0S1V2A0")
pointers = {
  dep: {"task_id": dep, "task_status": "cancelled", "parent": None, "sub_tasks": [], "relates_to": [
    {"path": work, "kind": "blocks"}
  ]},
  work: {"task_id": work, "task_status": "open", "parent": None, "sub_tasks": [], "relates_to": [
    {"path": dep, "kind": "dependency"}
  ]},
}
assert derived_blocked(pointers, work, atlas_id=a) is False, "cancelled must clear derived blocked"
pointers[dep]["task_status"] = "done"
assert derived_blocked(pointers, work, atlas_id=a) is False
print("not-blocked when kind:dependency target cancelled")
PY
  pass "dependency-terminal: not-blocked when kind:dependency target cancelled"
}
run_check dependency-terminal check_dependency_terminal

check_dependency_cycle() {
  python3 - <<PY || fail "dependency-cycle"
exec(open("$HELPERS").read())
a = "github.com/example/demo"
ta = task_id_for(a, "01J8E3K7M4Q2V8X5N6P9R0T1YZ")
tb = task_id_for(a, "01J8E3K8N5R3W9Y6P7Q0S1V2A0")
pointers = {
  ta: {"task_id": ta, "task_status": "open", "parent": None, "sub_tasks": [], "relates_to": [
    {"path": tb, "kind": "dependency"}
  ]},
  tb: {"task_id": tb, "task_status": "open", "parent": None, "sub_tasks": [], "relates_to": [
    {"path": ta, "kind": "blocks"}
  ]},
}
u_list = "01J8E3K9P6S4X0Z7Q8R1T2W3B1"
ta_path = path_for(ulid_of(ta), "alpha", folder=f"tasks/{u_list}-trip")
tb_path = path_for(ulid_of(tb), "beta")
registry = {
  ta_path: {"type": "task", "is_pointer": True},
  tb_path: {"type": "task", "is_pointer": True},
}
assert resolve_tid(pointers, ta_path, a) == ta
try:
    dual_write_set_dependency(pointers, tb, ta_path, registry, atlas_id=a)
    raise SystemExit("should have failed closed on dependency cycle")
except SystemExit as e:
    if "dependency cycle" not in str(e):
        raise
print("fail-closed: dependency cycle")
assert not any(e.get("kind") == "dependency" for e in pointers[tb]["relates_to"])
PY
  pass "dependency-cycle: fail-closed: dependency cycle"
}
run_check dependency-cycle check_dependency_cycle

# ---------------------------------------------------------------------------
# v0.6 task-list / filename checks
# ---------------------------------------------------------------------------
check_filename_ulid_and_name() {
  grep -q '<ULID>-<file-safe-name>' "$SKILL/SKILL.md" || fail "SKILL missing ULID-plus-name pin"
  python3 - <<PY || fail "filename-ulid-and-name"
exec(open("$HELPERS").read())
assert file_safe_name("Hello World!") == "hello-world"
assert file_safe_name("") == "item"
uid = "01J8E3K7M4Q2V8X5N6P9R0T1YZ"
assert path_for_named(uid, "demo-task") == f"tasks/{uid}-demo-task.md"
folder, lpath = list_path(uid, "trip")
assert folder == f"tasks/{uid}-trip"
assert lpath.endswith(".task-list.md")
assert lpath.startswith(folder + "/")
print("filename ULID-plus-name ok")
PY
  pass "filename-ulid-and-name: ULID-hyphen-file-safe-name"
}
run_check filename-ulid-and-name check_filename_ulid_and_name

check_task_list_suffix_matches_type() {
  grep -q '.task-list.md' "$SKILL/SKILL.md" || fail "SKILL missing .task-list.md suffix pin"
  grep -q 'tasks/index.md' "$SKILL/SKILL.md" || fail "SKILL missing root index exception"
  python3 - <<PY || fail "task-list-suffix-matches-type"
exec(open("$HELPERS").read())
uid = "01J8E3K7M4Q2V8X5N6P9R0T1YZ"
assert suffix_ok("tasks/index.md", "task-list", is_root_index=True)
assert suffix_ok("/var/atlas/tasks/index.md", "task-list", is_root_index=True)
assert suffix_ok("atlas/tasks/index.md", "task-list", is_root_index=True)
assert not suffix_ok("mytasks/index.md", "task-list", is_root_index=True)
assert not suffix_ok("/var/atlas/mytasks/index.md", "task-list", is_root_index=True)
assert suffix_ok(f"tasks/{uid}-trip/{uid}-trip.task-list.md", "task-list", is_root_index=False)
assert not suffix_ok(f"tasks/{uid}-trip/{uid}-trip.md", "task-list", is_root_index=False)
assert suffix_ok(f"tasks/{uid}-demo.md", "task", is_root_index=False)
assert not suffix_ok(f"tasks/{uid}-demo.task-list.md", "task", is_root_index=False)
print("type task-list ends in .task-list.md except tasks/index.md; type task does not")
PY
  pass "task-list-suffix-matches-type: type task-list ends in .task-list.md except tasks/index.md; type task does not"
}
run_check task-list-suffix-matches-type check_task_list_suffix_matches_type

check_listed_task_not_loose_on_index() {
  python3 - <<PY || fail "listed-task-not-loose-on-index"
exec(open("$HELPERS").read())
a = "github.com/example/demo"
root = task_id_for(a, "01J8E3K7M4Q2V8X5N6P9R0T1YZ")
lst = task_id_for(a, "01J8E3K8N5R3W9Y6P7Q0S1V2A0")
mem = task_id_for(a, "01J8E3K9P6S4X0Z7Q8R1T2W3B1")
loose = task_id_for(a, "01J8E3KAQ7T5Y1A8S9T2V3X4C2")
nodes = {
  root: {"type": "task-list", "task_id": root, "tasks": [lst, loose]},
  lst: {"type": "task-list", "task_id": lst, "task_list": root, "tasks": [mem]},
  mem: {"type": "task", "task_id": mem, "task_list": lst},
  loose: {"type": "task", "task_id": loose, "task_list": None},
}
compliance_walk(nodes, root)
nodes[root]["tasks"] = [lst, loose, mem]
try:
    compliance_walk(nodes, root)
    raise SystemExit("should reject listed task on root")
except SystemExit as e:
    if "listed task also loose" not in str(e):
        raise
print("a task URI inside a child list is absent from root tasks")
PY
  pass "listed-task-not-loose-on-index: a task URI inside a child list is absent from root tasks"
}
run_check listed-task-not-loose-on-index check_listed_task_not_loose_on_index

check_list_link_does_not_copy_tasks() {
  python3 - <<PY || fail "list-link-does-not-copy-tasks"
exec(open("$HELPERS").read())
a = "github.com/example/demo"
root = task_id_for(a, "01J8E3K7M4Q2V8X5N6P9R0T1YZ")
la = task_id_for(a, "01J8E3K8N5R3W9Y6P7Q0S1V2A0")
lb = task_id_for(a, "01J8E3K9P6S4X0Z7Q8R1T2W3B1")
tb = task_id_for(a, "01J8E3KAQ7T5Y1A8S9T2V3X4C2")
nodes = {
  root: {"type": "task-list", "task_id": root, "tasks": [la]},
  la: {"type": "task-list", "task_id": la, "task_list": root, "tasks": [lb]},
  lb: {"type": "task-list", "task_id": lb, "task_list": la, "tasks": [tb]},
  tb: {"type": "task", "task_id": tb, "task_list": lb},
}
compliance_walk(nodes, root)
nodes[la]["tasks"] = [lb, tb]
try:
    compliance_walk(nodes, root)
    raise SystemExit("should reject copied tasks")
except SystemExit as e:
    if "list-link copied" not in str(e):
        raise
print("a list pointer does not duplicate the target list task URIs")
PY
  pass "list-link-does-not-copy-tasks: a list pointer does not duplicate the target list task URIs"
}
run_check list-link-does-not-copy-tasks check_list_link_does_not_copy_tasks

check_rename_keeps_ulid_uri() {
  grep -qE 'renames the file|rename the file' "$SKILL/SKILL.md" "$SKILL/references/paths/update.md" \
    || fail "docs must say title change renames file"
  grep -qE 'rewrites body mentions|rewrite body mentions' "$SKILL/SKILL.md" "$SKILL/references/paths/update.md" \
    || fail "docs must rewrite body mentions on rename"
  grep -qE 'never rename the root|keeps the reserved path .tasks/index.md.|keep path .tasks/index.md. unchanged|title edits never rename the root' \
    "$SKILL/SKILL.md" "$SKILL/references/paths/update.md" \
    || fail "docs must exempt root tasks/index.md from title-driven renames"
  python3 - <<PY || fail "rename-keeps-ulid-uri"
exec(open("$HELPERS").read())
a = "github.com/example/demo"
uid = "01J8E3K7M4Q2V8X5N6P9R0T1YZ"
tid = task_id_for(a, uid)
old = path_for_named(uid, "old-title")
new = path_for_named(uid, file_safe_name("New Title"))
assert ulid_of(tid) == uid
assert tid == task_id_for(a, uid)
assert old != new
assert old.startswith(f"tasks/{uid}-")
assert new.startswith(f"tasks/{uid}-")
folder_entries = [old, "tasks/other.md"]
matched = [e for e in folder_entries if e.startswith(f"tasks/{uid}-") or e == f"tasks/{uid}.md"]
assert matched == [old]
print("title change keeps task_id URI and ULID; slug path is not the id; no store-wide scan")
PY
  pass "rename-keeps-ulid-uri: title change keeps task_id URI and ULID; slug path is not the id; no store-wide scan"
}
run_check rename-keeps-ulid-uri check_rename_keeps_ulid_uri

check_member_lives_in_list_folder() {
  grep -qE 'member tasks live in that folder|Member tasks live in that folder|Tasks in that cluster live' "$SKILL/SKILL.md" \
    || fail "SKILL missing list-folder membership pin"
  python3 - <<PY || fail "member-lives-in-list-folder"
exec(open("$HELPERS").read())
uid_l = "01J8E3K8N5R3W9Y6P7Q0S1V2A0"
uid_t = "01J8E3K9P6S4X0Z7Q8R1T2W3B1"
folder, lpath = list_path(uid_l, "trip")
member = f"{folder}/{uid_t}-pack.md"
loose = path_for_named(uid_t, "pack")
assert member.startswith(folder + "/")
assert not loose.startswith(folder + "/")
print("task with task_list L is inside L folder; loose task is not")
PY
  pass "member-lives-in-list-folder: task with task_list L is inside L folder; loose task is not"
}
run_check member-lives-in-list-folder check_member_lives_in_list_folder

check_membership_both_sides() {
  grep -q 'Dual-write the new list'"'"'s parent edge (root by default) before removing member URIs from the root' \
    "$SKILL/references/paths/migrate.md" \
    || fail "migrate must dual-write the new list parent edge before removing member URIs"
  grep -q 'Dual-write the new list'"'"'s parent edge (root by default) before removing member URIs from the root' \
    "$README_CONTRIB" \
    || fail "overlay README migrate must dual-write the new list parent edge before removing member URIs"
  grep -qE 'fail closed before any folder move|before any folder move or dual-write|Fail closed first if the new parent'     "$SKILL/references/paths/update.md"     || fail "update path must fail closed on list cycles before folder move/dual-write"
  grep -qE 'before.*folder move or dual-write|before any folder move' "$SKILL/SKILL.md"     || fail "SKILL must fail closed on list cycles before folder move/dual-write"
  python3 - <<PY || fail "membership-both-sides"
exec(open("$HELPERS").read())
a = "github.com/example/demo"
root = task_id_for(a, "01J8E3K7M4Q2V8X5N6P9R0T1YZ")
lst = task_id_for(a, "01J8E3K8N5R3W9Y6P7Q0S1V2A0")
mem = task_id_for(a, "01J8E3K9P6S4X0Z7Q8R1T2W3B1")
nodes = {
  root: {"type": "task-list", "task_id": root, "tasks": [lst, mem]},
  lst: {"type": "task-list", "task_id": lst, "task_list": root, "tasks": []},
  mem: {"type": "task", "task_id": mem, "task_list": None},
}
try:
    dual_write_set_membership(nodes, mem, lst)
    raise SystemExit("should require root_id for loose→list")
except SystemExit as e:
    if "loose→list membership requires root_id" not in str(e):
        raise
assert mem in nodes[root]["tasks"]
dual_write_set_membership(nodes, mem, lst, root)
assert nodes[mem]["task_list"] == lst
assert mem in nodes[lst]["tasks"]
assert mem not in nodes[root]["tasks"]
compliance_walk(nodes, root)
nodes[mem]["task_list"] = root
try:
    compliance_walk(nodes, root)
    raise SystemExit("should fail both-sides")
except SystemExit as e:
    if "both-sides" not in str(e):
        raise
print("task_list and list tasks agree after one skill write; compliance fails on drift")
# child list task_list must match the list that points at it
drift = {
  root: {"type": "task-list", "task_id": root, "tasks": [lst]},
  lst: {"type": "task-list", "task_id": lst, "task_list": mem, "tasks": []},
  mem: {"type": "task", "task_id": mem, "task_list": None},
}
try:
    compliance_walk(drift, root)
    raise SystemExit("should fail list-to-list drift")
except SystemExit as e:
    if "both-sides" not in str(e):
        raise
# self link
self_link = {
  root: {"type": "task-list", "task_id": root, "tasks": [root]},
}
try:
    compliance_walk(self_link, root)
    raise SystemExit("should fail self list link")
except SystemExit as e:
    if "cyclic list link" not in str(e):
        raise
# root task_list self-reference is forbidden (omit always)
root_self_tl = {
  root: {"type": "task-list", "task_id": root, "task_list": root, "tasks": []},
}
try:
    compliance_walk(root_self_tl, root)
    raise SystemExit("should fail root task_list self-reference")
except SystemExit as e:
    if "root must omit task_list" not in str(e):
        raise
# dual-write must reject list self-link / descendant reparent BEFORE mutating
la = task_id_for(a, "01J8E3KFN5R3W9Y6P7Q0S1V2C9")
lb = task_id_for(a, "01J8E3KGN5R3W9Y6P7Q0S1V2D0")
tree = {
  root: {"type": "task-list", "task_id": root, "tasks": [la]},
  la: {"type": "task-list", "task_id": la, "task_list": root, "tasks": [lb]},
  lb: {"type": "task-list", "task_id": lb, "task_list": la, "tasks": []},
}
snap = {k: dict(v) for k, v in tree.items()}
for k, v in snap.items():
    if "tasks" in v:
        snap[k] = dict(v)
        snap[k]["tasks"] = list(v["tasks"])
try:
    dual_write_set_membership(tree, la, la, root)
    raise SystemExit("should fail self list link on dual-write")
except SystemExit as e:
    if "cyclic list link" not in str(e):
        raise
assert tree[la]["task_list"] == snap[la]["task_list"], "self-link dual-write must not mutate"
assert list(tree[la]["tasks"]) == list(snap[la]["tasks"]), "self-link dual-write must not mutate tasks"
try:
    dual_write_set_membership(tree, la, lb, root)
    raise SystemExit("should fail descendant reparent on dual-write")
except SystemExit as e:
    if "cyclic list link" not in str(e):
        raise
assert tree[la]["task_list"] == snap[la]["task_list"], "descendant dual-write must not mutate"
assert list(tree[root]["tasks"]) == list(snap[root]["tasks"]), "descendant dual-write must not mutate root"
assert would_list_membership_cycle(tree, la, la) is True
assert would_list_membership_cycle(tree, la, lb) is True
assert would_list_membership_cycle(tree, lb, root) is False
# cycle back to root
cycle = {
  root: {"type": "task-list", "task_id": root, "tasks": [lst]},
  lst: {"type": "task-list", "task_id": lst, "task_list": root, "tasks": [root]},
}
try:
    compliance_walk(cycle, root)
    raise SystemExit("should fail cyclic list link")
except SystemExit as e:
    if "cyclic list link" not in str(e):
        raise
# non-task target fails closed even when task_list matches
doc = task_id_for(a, "01J8E3KBQ7T5Y1A8S9T2V3X4D3")
bad_type = {
  root: {"type": "task-list", "task_id": root, "tasks": [doc]},
  doc: {"type": "document", "task_id": doc, "task_list": root},
}
try:
    compliance_walk(bad_type, root)
    raise SystemExit("should fail non-task target")
except SystemExit as e:
    if "not a task" not in str(e):
        raise
# same ULID on two physical graph owners; membership lists URI only
uid_mem = ulid_of(mem)
phys_a = f"tasks/{uid_mem}-item.md"
phys_b = f"tasks/other-list/{uid_mem}-copy.md"
colliding = {
  root: {"type": "task-list", "task_id": root, "tasks": [mem]},
  phys_a: {"type": "task", "task_id": mem, "task_list": None},
  phys_b: {"type": "task", "task_id": mem, "task_list": None},
}
try:
    compliance_walk(colliding, root)
    raise SystemExit("should fail ULID collision")
except SystemExit as e:
    if "ULID collision" not in str(e):
        raise
# root URI plus a second physical graph key with the same task_id.
# The duplicate is not a child reference, so only root owner resolution catches it.
phys_root = f"tasks/{ulid_of(root)}-shadow.task-list.md"
root_dup = {
  root: {"type": "task-list", "task_id": root, "tasks": []},
  phys_root: {"type": "task-list", "task_id": root, "tasks": []},
}
try:
    reachable_ulid_owner(root_dup, root)
    raise SystemExit("should fail root ULID collision")
except SystemExit as e:
    if "ULID collision" not in str(e):
        raise
try:
    compliance_walk(root_dup, root)
    raise SystemExit("should fail root ULID collision on compliance")
except SystemExit as e:
    if "ULID collision" not in str(e):
        raise
assert ulid_taken(root_dup, root, ulid_of(root)) is True
unique_root = {
  root: {"type": "task-list", "task_id": root, "tasks": []},
}
assert resolve_tasks_ref(unique_root, root) == [root]
assert reachable_ulid_owner(unique_root, root).get(ulid_of(root)) == root
compliance_walk(unique_root, root)
# path/slug membership entries are rejected (URI-shaped only)
bad_path_mem = {
  root: {"type": "task-list", "task_id": root, "tasks": [phys_a]},
  phys_a: {"type": "task", "task_id": mem, "task_list": None},
}
try:
    compliance_walk(bad_path_mem, root)
    raise SystemExit("should fail non-URI tasks entry")
except SystemExit as e:
    if "tasks entry must be atlas://" not in str(e):
        raise
fresh = "01J8E3KCQ7T5Y1A8S9T2V3X4E4"
assert ulid_taken({
  root: {"type": "task-list", "task_id": root, "tasks": [lst]},
  lst: {"type": "task-list", "task_id": lst, "task_list": root, "tasks": [mem]},
  mem: {"type": "task", "task_id": mem, "task_list": lst},
}, root, uid_mem) is True
assert ulid_taken({
  root: {"type": "task-list", "task_id": root, "tasks": [lst]},
  lst: {"type": "task-list", "task_id": lst, "task_list": root, "tasks": []},
}, root, fresh) is False
# dangling reachable pointer still records its URI for collision checks
dangling = task_id_for(a, "01J8E3KDQ7T5Y1A8S9T2V3X4F5")
assert ulid_taken({
  root: {"type": "task-list", "task_id": root, "tasks": [dangling]},
}, root, ulid_of(dangling)) is True
# loose root task must omit task_list; root URI is not an empty form
loose_root = task_id_for(a, "01J8E3KEQ7T5Y1A8S9T2V3X4G6")
loose_bad = {
  root: {"type": "task-list", "task_id": root, "tasks": [loose_root]},
  loose_root: {"type": "task", "task_id": loose_root, "task_list": root},
}
try:
    compliance_walk(loose_bad, root)
    raise SystemExit("should fail loose task with root task_list")
except SystemExit as e:
    if "loose task must omit task_list" not in str(e):
        raise
loose_ok = {
  root: {"type": "task-list", "task_id": root, "tasks": [loose_root]},
  loose_root: {"type": "task", "task_id": loose_root, "task_list": None},
}
compliance_walk(loose_ok, root)
rooted = {
  root: {"type": "task-list", "task_id": root, "tasks": [lst]},
  lst: {"type": "task-list", "task_id": lst, "task_list": root, "tasks": [mem]},
  mem: {"type": "task", "task_id": mem, "task_list": lst},
}
snap_tl = rooted[mem]["task_list"]
snap_root_tasks = list(rooted[root]["tasks"])
snap_lst_tasks = list(rooted[lst]["tasks"])
try:
    dual_write_set_membership(rooted, mem, root, root)
    raise SystemExit("should reject root target for task member")
except SystemExit as e:
    if "task membership target is root" not in str(e):
        raise
assert rooted[mem]["task_list"] == snap_tl
assert list(rooted[root]["tasks"]) == snap_root_tasks
assert list(rooted[lst]["tasks"]) == snap_lst_tasks
try:
    dual_write_set_membership(rooted, mem, root)
    raise SystemExit("should reject root target for task member without root_id")
except SystemExit as e:
    if "task membership target is root" not in str(e):
        raise
assert rooted[mem]["task_list"] == snap_tl
assert list(rooted[lst]["tasks"]) == snap_lst_tasks
nested = task_id_for(a, "01J8E3KHN5R3W9Y6P7Q0S1V2E1")
rooted[lst]["tasks"] = [mem, nested]
rooted[nested] = {"type": "task-list", "task_id": nested, "task_list": lst, "tasks": []}
dual_write_set_membership(rooted, nested, root, root)
assert rooted[nested]["task_list"] == root
assert nested in rooted[root]["tasks"]
assert nested not in rooted[lst]["tasks"]
assert rooted[mem]["task_list"] == lst
compliance_walk(rooted, root)
print("task root target rejected before mutate; nested list may set task_list to root")
PY
  pass "membership-both-sides: task_list and list tasks agree; compliance fails on drift"
}
run_check membership-both-sides check_membership_both_sides

check_clear_membership_reparents_to_root() {
  grep -qE 'clear membership requires root_id|reparents onto root' \
    "$SKILL/scripts/smoke-check.sh" \
    || fail "smoke helper must require root_id on clear"
  grep -qE 'Reparent it to the \*\*root\*\*|append the URI to the root' \
    "$SKILL/references/paths/update.md" \
    || fail "update path must reparent cleared membership to root"
  grep -q 'remove the list URI from the former parent' \
    "$SKILL/references/paths/update.md" \
    || fail "update path must remove nested list from former parent on clear"
  grep -qE 'loose→list membership requires root_id|loose root.tasks row is removed' \
    "$SKILL/scripts/smoke-check.sh" \
    || fail "smoke helper must drop root loose row on loose→list"
  python3 - <<PY || fail "clear-membership-reparents-to-root"
exec(open("$HELPERS").read())
a = "github.com/example/demo"
root = task_id_for(a, "01J8E3K7M4Q2V8X5N6P9R0T1YZ")
lst = task_id_for(a, "01J8E3K8N5R3W9Y6P7Q0S1V2A0")
mem = task_id_for(a, "01J8E3K9P6S4X0Z7Q8R1T2W3B1")
nested = task_id_for(a, "01J8E3KAN5R3W9Y6P7Q0S1V2B2")
nodes = {
  root: {"type": "task-list", "task_id": root, "tasks": [lst]},
  lst: {"type": "task-list", "task_id": lst, "task_list": root, "tasks": [mem, nested]},
  mem: {"type": "task", "task_id": mem, "task_list": lst},
  nested: {"type": "task-list", "task_id": nested, "task_list": lst, "tasks": []},
}
snap_tl = nodes[mem]["task_list"]
try:
    dual_write_set_membership(nodes, mem, None)
    raise SystemExit("should require root_id")
except SystemExit as e:
    if "requires root_id" not in str(e):
        raise
assert nodes[mem]["task_list"] == snap_tl
assert mem in nodes[lst]["tasks"]
dual_write_set_membership(nodes, mem, None, root)
assert nodes[mem]["task_list"] is None
assert mem not in nodes[lst]["tasks"]
assert mem in nodes[root]["tasks"]
compliance_walk(nodes, root)
dual_write_set_membership(nodes, nested, None, root)
assert nodes[nested]["task_list"] == root
assert nested not in nodes[lst]["tasks"]
assert nested in nodes[root]["tasks"]
compliance_walk(nodes, root)
print("clear membership reparents task (loose) and nested list onto root before mutate")
PY
  pass "clear-membership-reparents-to-root: clear requires root_id; task becomes loose on root; nested list reparents to root"
}
run_check clear-membership-reparents-to-root check_clear_membership_reparents_to_root

# ---------------------------------------------------------------------------
# Full-run fixture: index/compile + relation fixture (ULID-plus-name + task-list root)
# Runs on a default `init` store and on an `init --schema-version 2.0` store,
# because only SCHEMA 2.0 validates overlay root keys strictly.
# Usage: run_install_fixture <label> <expected schema_version or ""> [init args...]
# ---------------------------------------------------------------------------
run_install_fixture() {
  local label="$1" want_sv="$2"
  shift 2
  FIX=$(mktemp -d)
  python3 "$ATLAS_CLI" init --root "$FIX" "$@" >/dev/null
  # Atlas root contract file: CONTRACT.json (Atlas 0.13+) or SCHEMA.json (older).
  local store_file="$FIX/CONTRACT.json"
  [[ -f "$store_file" ]] || store_file="$FIX/SCHEMA.json"
  [[ -f "$store_file" ]] || fail "init ($label) wrote neither CONTRACT.json nor SCHEMA.json"
  local sv
  read -r AID sv < <(python3 -c "import json; o=json.load(open('$store_file')); print(o['atlas_id'], o.get('schema_version', '1.0'))")
  [[ -n "$AID" ]] || fail "init ($label): empty atlas_id"
  if [[ -n "$want_sv" && "$sv" != "$want_sv" ]]; then
    fail "init ($label) produced schema_version=$sv, expected $want_sv"
  fi
  python3 "$ATLAS_CLI" schema install "$SKILL/contributions/atlas-tasks" --root "$FIX" \
    || fail "schema install on $label store (schema_version=$sv)"
  pass "4a schema install on $label store (schema_version=$sv)"
  U_DEMO="01J8E3K7M4Q2V8X5N6P9R0T1YZ"
  U_PARENT="01J8E3K8N5R3W9Y6P7Q0S1V2A0"
  U_CHILD="01J8E3K9P6S4X0Z7Q8R1T2W3B1"
  TID_DEMO="atlas://${AID}/tasks/${U_DEMO}"
  TID_PARENT="atlas://${AID}/tasks/${U_PARENT}"
  TID_CHILD="atlas://${AID}/tasks/${U_CHILD}"

  U_ROOT="01J8E3K6M3P1V7W4M5N8Q9S0XY"
  U_LIST="01J8E3KBR8V6Z2B9T0V3V4Y5D3"
  U_HAND="01J8E3KCS9W7A3C0V1W4X5Z6E4"
  TID_ROOT="atlas://${AID}/tasks/${U_ROOT}"
  TID_LIST="atlas://${AID}/tasks/${U_LIST}"
  TID_HAND="atlas://${AID}/tasks/${U_HAND}"
  N_DEMO="demo-task"
  N_PARENT="parent-a"
  N_CHILD="child-b"
  N_LIST="trip"
  N_HAND="hand-task"
  mkdir -p "$FIX/tasks/${U_LIST}-${N_LIST}" "$FIX/knowledge/demo"
  cat > "$FIX/knowledge/demo/index.md" <<'MD'
---
type: document
title: Demo knowledge folder
created: "2026-10-01"
---
Index for the demo knowledge folder used by atlas-tasks smoke fixtures.
MD
  cat > "$FIX/knowledge/demo/note.md" <<'MD'
---
type: document
title: Demo note
created: "2026-10-01"
---
This related knowledge node sits beside colocated task bodies in the atlas-tasks smoke fixture.
MD
  cat > "$FIX/knowledge/demo/todo-demo.md" <<'MD'
---
type: document
title: "Task body — demo"
created: "2026-10-01"
---
Do the demo thing: flesh out enough prose so Atlas compile accepts this colocated task body page.
MD
  cat > "$FIX/tasks/${U_DEMO}-${N_DEMO}.md" <<MD
---
type: task
title: "Demo task"
created: "2026-10-01"
task_id: ${TID_DEMO}
task_status: open
body_path: knowledge/demo/todo-demo.md
related_node: knowledge/demo/note.md
assignees:
  - alice
parent: null
sub_tasks: []
relates_to:
  - path: ${TID_CHILD}
    kind: blocks
---
## Content

Pointer only — full prose lives at body_path; this task page must remain a short pointer for the index.
MD
  cat > "$FIX/tasks/${U_PARENT}-${N_PARENT}.md" <<MD
---
type: task
title: "Parent A"
created: "2026-10-01"
task_id: ${TID_PARENT}
task_status: open
body_path: knowledge/demo/todo-demo.md
related_node: knowledge/demo/note.md
assignees: []
parent: null
sub_tasks:
  - ${TID_CHILD}
relates_to: []
---
## Content

Parent pointer for hierarchy dual-write smoke; body shared for fixture brevity.
MD
  cat > "$FIX/tasks/${U_LIST}-${N_LIST}/${U_CHILD}-${N_CHILD}.md" <<MD
---
type: task
title: "Child B"
created: "2026-10-01"
task_id: ${TID_CHILD}
task_status: in_progress
body_path: knowledge/demo/todo-demo.md
related_node: knowledge/demo/note.md
assignees:
  - bob
parent: ${TID_PARENT}
sub_tasks: []
task_list: ${TID_LIST}
relates_to:
  - path: ${TID_DEMO}
    kind: dependency
---
## Content

Child pointer with parent and kind:dependency edge for derived-blocked index column smoke.
MD
  cat > "$FIX/tasks/${U_HAND}-${N_HAND}.md" <<MD
---
type: task
title: "Legacy task"
created: "2026-10-01"
task_id: ${TID_HAND}
task_status: open
body_path: knowledge/demo/todo-demo.md
related_node: knowledge/demo/note.md
assignees: [ada]
parent: ~
sub_tasks: []
# hand-written: keep quoting, comments, and folded scalars
status: open
priority: medium
origin: user
sensitivity: internal
description: >-
  Manually written folded description
  that must survive a status-only update.
relates_to:
  - path: knowledge/demo/note.md
    kind: related
---
## Content

Pointer only. Full prose lives in the colocated body page; this hand-written task page stays a short pointer.
MD
  cat > "$FIX/tasks/${U_LIST}-${N_LIST}/${U_LIST}-${N_LIST}.task-list.md" <<MD
---
type: task-list
title: "Trip"
created: "2026-10-01"
task_id: ${TID_LIST}
task_list: ${TID_ROOT}
tasks:
  - ${TID_CHILD}
---
## Members

Trip task list for the atlas-tasks smoke fixture. Membership is the frontmatter
tasks pointers plus these body mentions. Do not copy nested list members here.

- Child B — ${TID_CHILD}

This list owns its folder; child tasks live beside this file. Parent and sub_tasks
hierarchy on Child B is separate from list membership.
MD
  cat > "$FIX/tasks/index.md" <<MD
---
type: task-list
title: Tasks index
created: "2026-10-01"
task_id: ${TID_ROOT}
tasks:
  - ${TID_LIST}
  - ${TID_DEMO}
  - ${TID_PARENT}
  - ${TID_HAND}
---
## Members

Root task list: other lists and loose tasks only. Child-list members are not loose rows here.

- Trip list — ${TID_LIST}
- Demo task — ${TID_DEMO}
- Parent A — ${TID_PARENT}
- Legacy task — ${TID_HAND}

| ulid | title | status | task_path | body_path | related_node | assignees | parent | dependency | blocked | task_list |
|---|---|---|---|---|---|---|---|---|---|---|
| ${U_LIST} | Trip | list | tasks/${U_LIST}-${N_LIST}/${U_LIST}-${N_LIST}.task-list.md |  |  |  |  |  |  |  |
| ${U_DEMO} | Demo task | open | tasks/${U_DEMO}-${N_DEMO}.md | knowledge/demo/todo-demo.md | knowledge/demo/note.md | alice |  |  | no |  |
| ${U_PARENT} | Parent A | open | tasks/${U_PARENT}-${N_PARENT}.md | knowledge/demo/todo-demo.md | knowledge/demo/note.md |  |  |  | no |  |
MD

  [[ -f "$FIX/tasks/index.md" ]] || fail "missing index"
  grep -q 'type: task-list' "$FIX/tasks/index.md" || fail "index must be type task-list"
  grep -q 'knowledge/demo/todo-demo.md' "$FIX/tasks/index.md" || fail "index missing body pointer"
  grep -q 'Do the demo thing' "$FIX/knowledge/demo/todo-demo.md" || fail "body missing prose"
  grep -q 'Do the demo thing' "$FIX/tasks/index.md" && fail "index dumped full body" || true
  [[ -f "$FIX/tasks/${U_DEMO}-${N_DEMO}.md" ]] || fail "missing ULID-plus-name task pointer"
  [[ -f "$FIX/tasks/${U_LIST}-${N_LIST}/${U_LIST}-${N_LIST}.task-list.md" ]] || fail "missing list file"
  [[ -f "$FIX/tasks/${U_LIST}-${N_LIST}/${U_CHILD}-${N_CHILD}.md" ]] || fail "member not in list folder"
  [[ ! -d "$FIX/tasks/tasks" ]] || fail "fixture must not use nested tasks/tasks/"
  grep -q 'assignees' "$FIX/tasks/index.md" || fail "index missing assignees column"
  grep -q 'kind: dependency' "$FIX/tasks/${U_LIST}-${N_LIST}/${U_CHILD}-${N_CHILD}.md" || fail "fixture missing kind: dependency"
  grep -q 'kind: blocks' "$FIX/tasks/${U_DEMO}-${N_DEMO}.md" || fail "fixture missing kind: blocks"
  grep -q "atlas://" "$FIX/tasks/${U_DEMO}-${N_DEMO}.md" || fail "fixture missing atlas:// task_id"
  grep -q 'task_list:' "$FIX/tasks/${U_LIST}-${N_LIST}/${U_CHILD}-${N_CHILD}.md" || fail "member missing task_list"
  grep -q 'depends_on' "$FIX/tasks/${U_LIST}-${N_LIST}/${U_CHILD}-${N_CHILD}.md" && fail "fixture still has depends_on" || true
  grep -q 'display_slug' "$FIX/tasks/${U_LIST}-${N_LIST}/${U_CHILD}-${N_CHILD}.md" && fail "fixture has display_slug" || true
  python3 - <<PY || fail "fixture root lists child as loose"
import re
idx=open("$FIX/tasks/index.md").read()
m=re.search(r"^tasks:\n((?:  - .*\n)+)", idx, re.M)
assert m, "no tasks block"
block=m.group(1)
assert "$TID_CHILD" not in block, "child must not be loose on root"
assert "$TID_LIST" in block and "$TID_DEMO" in block
print("root tasks ok")
PY
  pass "3 index task-list + colocated body + ULID-plus-name pointer + list folder + dependency columns"

  # v0.7 pin 23: generated list-folder index (dry run writes nothing; apply; idempotent rerun).
  LFI="$SKILL/scripts/list-folder-index.py"
  python3 "$LFI" --root "$FIX" --dry-run | grep -Fq "would create tasks/${U_LIST}-${N_LIST}/index.md" \
    || fail "list-folder-index dry run must report would create"
  [[ ! -e "$FIX/tasks/${U_LIST}-${N_LIST}/index.md" ]] || fail "dry run wrote index.md"
  python3 "$LFI" --root "$FIX" >/dev/null || fail "list-folder-index apply"
  idx="$FIX/tasks/${U_LIST}-${N_LIST}/index.md"
  grep -Fxq "generated_by: atlas-tasks" "$idx" || fail "index.md missing generated_by marker"
  ! grep -Eq '^type:' "$idx" || fail "list-folder index.md must not carry type (pin 21/23)"
  grep -Fq "(${U_LIST}-${N_LIST}.task-list.md)" "$idx" || fail "index.md must link the list page"
  grep -Fq "\`${U_CHILD}\`" "$idx" || fail "index.md must list member ULIDs"
  python3 "$LFI" --root "$FIX" | grep -Fq "summary: create=0, update=0, ok=1" || fail "list-folder-index not idempotent"
  pass "4b list-folder-index: dry run, apply, idempotent ($label store)"
  python3 "$ATLAS_CLI" compile --root "$FIX" --json > "$FIX.compile.json" 2>/dev/null || true
  python3 - "$FIX.compile.json" <<'PY' || fail "index_md_present still fires on a list folder ($label store)"
import json,sys
o=json.load(open(sys.argv[1]))
bad=[w for w in o.get("warnings",[]) if w.get("id")=="index_md_present" and w.get("path","").startswith("tasks/")]
assert not bad, bad
PY
  rm -f "$FIX.compile.json"
  pass "4c compile: no index_md_present on list folders ($label store)"

  # v0.8 pin 24: tasks.py writer (dry-run, writes, fail-closed). Compile follows.
  TW="$SKILL/scripts/tasks.py"
  BODY="Colocated task body prose for the atlas-tasks writer smoke. This page holds the full task prose so compile accepts it."
  RELATED="knowledge/demo/note.md"
  hash_tree() {
    python3 - "$1" <<'PY'
import hashlib, os, sys
root = sys.argv[1]
h = hashlib.sha256()
for base in ("tasks", "knowledge"):
    top = os.path.join(root, base)
    for dirpath, dirnames, filenames in os.walk(top):
        dirnames.sort()
        for name in sorted(filenames):
            path = os.path.join(dirpath, name)
            if os.path.islink(path):
                continue
            rel = os.path.relpath(path, root)
            h.update(rel.encode())
            h.update(b"\0")
            with open(path, "rb") as fh:
                h.update(fh.read())
print(h.hexdigest())
PY
  }
  assert_unchanged() {
    local name="$1"
    shift
    local before after rc
    before="$(hash_tree "$FIX")"
    set +e
    PYTHONDONTWRITEBYTECODE=1 python3 "$TW" "$@" >"$FIX.writer.out" 2>"$FIX.writer.err"
    rc=$?
    set -e
    after="$(hash_tree "$FIX")"
    [[ "$before" == "$after" ]] || fail "tasks.py $name changed the tree ($label)"
    [[ "$rc" -ne 0 ]] || fail "tasks.py $name should fail ($label)"
    printf '%s' "$rc"
  }

  before="$(hash_tree "$FIX")"
  dry="$(PYTHONDONTWRITEBYTECODE=1 python3 "$TW" add --root "$FIX" --title "Dry task" \
    --related-node "$RELATED" --body "$BODY" --dry-run)"
  after="$(hash_tree "$FIX")"
  [[ "$before" == "$after" ]] || fail "tasks.py dry-run wrote files ($label)"
  printf '%s\n' "$dry" | python3 -c 'import json,sys; o=json.load(sys.stdin); assert o["ok"] is True and o["dry_run"] is True and o["command"]=="add"' \
    || fail "tasks.py dry-run receipt ($label)"

  loose="$(PYTHONDONTWRITEBYTECODE=1 python3 "$TW" add --root "$FIX" --title "Loose task" \
    --related-node "$RELATED" --body "$BODY")"
  read -r LOOSE_ID LOOSE_ULID LOOSE_PATH LOOSE_BODY < <(printf '%s\n' "$loose" | python3 -c 'import json,sys; o=json.load(sys.stdin); print(o["task_id"], o["ulid"], o["path"], o["body_path"])')
  [[ -f "$FIX/$LOOSE_PATH" ]] || fail "loose task file missing ($label)"
  [[ "$LOOSE_PATH" == "tasks/${LOOSE_ULID}-loose-task.md" ]] || fail "loose task path ($LOOSE_PATH)"
  [[ -f "$FIX/$LOOSE_BODY" ]] || fail "loose task body page missing ($label)"
  grep -Fq "$LOOSE_ID" "$FIX/tasks/index.md" || fail "root tasks missing loose task ($label)"
  python3 - "$FIX/$LOOSE_PATH" "$LOOSE_ID" <<'PY' || fail "loose task frontmatter ($label)"
import re, sys, yaml
text = open(sys.argv[1], encoding="utf-8").read()
meta = yaml.safe_load(re.match(r"^---\n(.*?)\n---", text, re.S).group(1))
assert meta["type"] == "task" and meta["task_id"] == sys.argv[2]
assert meta["task_status"] == "open" and "task_list" not in meta
assert meta["title"] == "Loose task"
PY

  trip="$(PYTHONDONTWRITEBYTECODE=1 python3 "$TW" add --root "$FIX" --title "Trip child" \
    --related-node "$RELATED" --body "$BODY" \
    --task-list "$TID_LIST" --parent "$TID_PARENT" --depends-on "$TID_DEMO")"
  read -r TRIP_ID TRIP_ULID TRIP_PATH < <(printf '%s\n' "$trip" | python3 -c 'import json,sys; o=json.load(sys.stdin); assert o["derived_blocked"] is True; assert o["task_list"]; assert o["parent"]; print(o["task_id"], o["ulid"], o["path"])')
  [[ "$TRIP_PATH" == "tasks/${U_LIST}-${N_LIST}/${TRIP_ULID}-trip-child.md" ]] || fail "trip task path ($TRIP_PATH)"
  [[ -f "$FIX/$TRIP_PATH" ]] || fail "trip task file missing ($label)"
  python3 - "$FIX" "$TRIP_ID" "$TRIP_ULID" "$TID_LIST" "$TID_PARENT" "$TID_DEMO" "$U_LIST" "$N_LIST" <<'PY' || fail "trip task links ($label)"
import re, sys, yaml
from pathlib import Path
fix, trip_id, trip_ulid, list_id, parent_id, demo_id, u_list, n_list = sys.argv[1:]
def meta(path):
    text = Path(path).read_text(encoding="utf-8")
    return yaml.safe_load(re.match(r"^---\n(.*?)\n---", text, re.S).group(1))
task = meta(Path(fix) / f"tasks/{u_list}-{n_list}/{trip_ulid}-trip-child.md")
assert task["task_list"] == list_id and task["parent"] == parent_id
assert any(e.get("kind") == "dependency" and e.get("path") == demo_id for e in task["relates_to"])
owner = meta(Path(fix) / f"tasks/{u_list}-{n_list}/{u_list}-{n_list}.task-list.md")
assert trip_id in owner["tasks"]
PY
  python3 - "$FIX/tasks/${U_PARENT}-${N_PARENT}.md" "$FIX/tasks/${U_DEMO}-${N_DEMO}.md" \
    "$FIX/tasks/${U_LIST}-${N_LIST}/index.md" "$TRIP_ID" "$TRIP_ULID" "$TID_DEMO" <<'PY' || fail "trip back-links ($label)"
import re, sys, yaml
from pathlib import Path
parent_p, demo_p, idx_p, trip_id, trip_ulid, demo_id = sys.argv[1:]
def meta(path):
    text = Path(path).read_text(encoding="utf-8")
    return yaml.safe_load(re.match(r"^---\n(.*?)\n---", text, re.S).group(1))
assert trip_id in meta(parent_p)["sub_tasks"]
demo = meta(demo_p)
assert any(e.get("kind") == "blocks" and e.get("path") == trip_id for e in demo["relates_to"])
idx = Path(idx_p).read_text(encoding="utf-8")
assert f"`{trip_ulid}`" in idx
PY

  lst="$(PYTHONDONTWRITEBYTECODE=1 python3 "$TW" add --root "$FIX" --kind task-list --title "Packing")"
  read -r LIST_ID LIST_ULID LIST_PATH < <(printf '%s\n' "$lst" | python3 -c 'import json,sys; o=json.load(sys.stdin); assert o["kind"]=="task-list"; print(o["task_id"], o["ulid"], o["path"])')
  [[ "$LIST_PATH" == "tasks/${LIST_ULID}-packing/${LIST_ULID}-packing.task-list.md" ]] || fail "new list path ($LIST_PATH)"
  [[ -f "$FIX/$LIST_PATH" ]] || fail "new list file missing ($label)"
  [[ -f "$FIX/tasks/${LIST_ULID}-packing/index.md" ]] || fail "new list index missing ($label)"
  grep -Fq "$LIST_ID" "$FIX/tasks/index.md" || fail "root missing new list ($label)"
  python3 - "$FIX/$LIST_PATH" "$TID_ROOT" <<'PY' || fail "new list frontmatter ($label)"
import re, sys, yaml
meta = yaml.safe_load(re.match(r"^---\n(.*?)\n---", open(sys.argv[1], encoding="utf-8").read(), re.S).group(1))
assert meta["type"] == "task-list" and meta["task_list"] == sys.argv[2] and meta["tasks"] == []
PY

  ren="$(PYTHONDONTWRITEBYTECODE=1 python3 "$TW" update --root "$FIX" --id "$LOOSE_ID" --title "Loose renamed")"
  read -r REN_ID REN_PATH < <(printf '%s\n' "$ren" | python3 -c 'import json,sys; o=json.load(sys.stdin); print(o["task_id"], o["path"])')
  [[ "$REN_ID" == "$LOOSE_ID" ]] || fail "rename changed task_id ($label)"
  [[ "$REN_PATH" == "tasks/${LOOSE_ULID}-loose-renamed.md" ]] || fail "renamed path ($REN_PATH)"
  [[ ! -e "$FIX/$LOOSE_PATH" ]] || fail "old loose path still present ($label)"
  [[ -f "$FIX/$REN_PATH" ]] || fail "renamed file missing ($label)"
  grep -Fq "${LOOSE_ULID}-loose-renamed.md" "$FIX/tasks/index.md" || fail "root mention not rewritten ($label)"
  grep -Fq "${LOOSE_ULID}-loose-task.md" "$FIX/tasks/index.md" && fail "old basename still in root ($label)" || true

  mov="$(PYTHONDONTWRITEBYTECODE=1 python3 "$TW" update --root "$FIX" --id "$LOOSE_ID" --task-list "$TID_LIST")"
  read -r MOV_PATH < <(printf '%s\n' "$mov" | python3 -c 'import json,sys; o=json.load(sys.stdin); print(o["path"])')
  [[ "$MOV_PATH" == "tasks/${U_LIST}-${N_LIST}/${LOOSE_ULID}-loose-renamed.md" ]] || fail "moved path ($MOV_PATH)"
  [[ -f "$FIX/$MOV_PATH" ]] || fail "moved file missing ($label)"
  [[ ! -e "$FIX/$REN_PATH" ]] || fail "loose path remains after move ($label)"
  python3 - "$FIX/tasks/index.md" "$FIX/tasks/${U_LIST}-${N_LIST}/${U_LIST}-${N_LIST}.task-list.md" \
    "$FIX/tasks/${U_LIST}-${N_LIST}/index.md" "$LOOSE_ID" "$LOOSE_ULID" <<'PY' || fail "move membership ($label)"
import re, sys, yaml
from pathlib import Path
root_p, list_p, idx_p, loose_id, loose_ulid = sys.argv[1:]
def meta(path):
    text = Path(path).read_text(encoding="utf-8")
    return yaml.safe_load(re.match(r"^---\n(.*?)\n---", text, re.S).group(1))
assert loose_id not in meta(root_p)["tasks"]
assert loose_id in meta(list_p)["tasks"]
assert f"`{loose_ulid}`" in Path(idx_p).read_text(encoding="utf-8")
PY

  PYTHONDONTWRITEBYTECODE=1 python3 "$TW" update --root "$FIX" --id "$TRIP_ID" --remove-dependency "$TID_DEMO" >/dev/null
  python3 - "$FIX/$TRIP_PATH" "$FIX/tasks/${U_DEMO}-${N_DEMO}.md" "$TRIP_ID" "$TID_DEMO" <<'PY' || fail "dependency not cleared both sides ($label)"
import re, sys, yaml
from pathlib import Path
def meta(path):
    text = Path(path).read_text(encoding="utf-8")
    return yaml.safe_load(re.match(r"^---\n(.*?)\n---", text, re.S).group(1))
waiter, blocker, trip_id, demo_id = sys.argv[1:]
assert not any(e.get("kind") == "dependency" and e.get("path") == demo_id for e in meta(waiter).get("relates_to") or [])
assert not any(e.get("kind") == "blocks" and e.get("path") == trip_id for e in meta(blocker).get("relates_to") or [])
PY

  comp="$(PYTHONDONTWRITEBYTECODE=1 python3 "$TW" complete --root "$FIX" --id "$LOOSE_ID")"
  printf '%s\n' "$comp" | python3 -c 'import json,sys; o=json.load(sys.stdin); assert o["ok"] is True and o["command"]=="complete"'
  python3 - "$FIX/$MOV_PATH" "$LOOSE_ID" <<'PY' || fail "complete did not set done ($label)"
import re, sys, yaml
meta = yaml.safe_load(re.match(r"^---\n(.*?)\n---", open(sys.argv[1], encoding="utf-8").read(), re.S).group(1))
assert meta["task_status"] == "done" and meta["task_id"] == sys.argv[2]
assert meta["body_path"] and meta["related_node"] and "relates_to" in meta
PY

  python3 "$LFI" --root "$FIX" | grep -Fq "create=0, update=0" \
    || fail "list-folder-index not idempotent after tasks.py ($label)"

  assert_unchanged "root task-list" add --root "$FIX" --title "Nope" --related-node "$RELATED" --body "$BODY" --task-list "$TID_ROOT" >/dev/null
  assert_unchanged "status blocked" add --root "$FIX" --title "Nope" --related-node "$RELATED" --body "$BODY" --status blocked >/dev/null
  assert_unchanged "cross-atlas parent" add --root "$FIX" --title "Nope" --related-node "$RELATED" --body "$BODY" \
    --parent "atlas://example.test/other/tasks/01J8E3KBR8V6Z2B9T0V3V4Y5D4" >/dev/null
  assert_unchanged "dependency on task-list" add --root "$FIX" --title "Nope" --related-node "$RELATED" --body "$BODY" \
    --depends-on "$TID_LIST" >/dev/null
  assert_unchanged "parent cycle" update --root "$FIX" --id "$TID_PARENT" --parent "$TID_CHILD" >/dev/null
  assert_unchanged "duplicate task-id" add --root "$FIX" --title "Nope" --related-node "$RELATED" --body "$BODY" \
    --task-id "$TID_DEMO" >/dev/null
  assert_unchanged "complete task-list" complete --root "$FIX" --id "$TID_LIST" >/dev/null
  rc="$(assert_unchanged "nested list reparent" update --root "$FIX" --id "$TID_LIST" --clear-task-list)"
  [[ "$rc" == "3" ]] || fail "nested list reparent must exit 3, got $rc ($label)"
  grep -Fq "manual" "$FIX.writer.out" || fail "exit 3 must mention the manual update path ($label)"
  rm -f "$FIX.writer.out" "$FIX.writer.err"

  # Manually written task: unknown keys, a comment, flow style, and a folded scalar.
  # A status-only update and complete must each touch exactly one task_status line.
  HAND="$FIX/tasks/${U_HAND}-${N_HAND}.md"
  [[ -f "$HAND" ]] || fail "hand-written task missing ($label)"
  cp "$HAND" "$FIX.hand.pristine"
  assert_one_status_line() {
    local before="$1" after="$2" what="$3"
    python3 - "$before" "$after" "$what" "$label" <<'PY' || fail "status diff ($label)"
import difflib, sys
before, after, what, label = sys.argv[1:]
a = open(before, encoding="utf-8").read().splitlines(keepends=True)
b = open(after, encoding="utf-8").read().splitlines(keepends=True)
diff = list(difflib.unified_diff(a, b, fromfile="before", tofile="after"))
removed = [ln for ln in diff if ln.startswith("-") and not ln.startswith("---")]
added = [ln for ln in diff if ln.startswith("+") and not ln.startswith("+++")]
if len(removed) != 1 or len(added) != 1 or "task_status" not in removed[0] or "task_status" not in added[0]:
    sys.stderr.write("".join(diff) or "(empty diff)\n")
    raise SystemExit(f"unified diff for {what} must touch exactly one task_status line ({label})")
print(f"one-line {what} diff ok")
PY
  }
  cmp -s "$FIX.hand.pristine" "$HAND" || fail "writer rewrote hand-written task before status update ($label)"
  cp "$HAND" "$FIX.hand.before"
  PYTHONDONTWRITEBYTECODE=1 python3 "$TW" update --root "$FIX" --id "$TID_HAND" --status in_progress >/dev/null
  assert_one_status_line "$FIX.hand.before" "$HAND" "update --status"
  cp "$HAND" "$FIX.hand.before"
  PYTHONDONTWRITEBYTECODE=1 python3 "$TW" complete --root "$FIX" --id "$TID_HAND" >/dev/null
  assert_one_status_line "$FIX.hand.before" "$HAND" "complete"
  python3 - "$HAND" <<'PY' || fail "hand-written keys not preserved ($label)"
import re, sys, yaml
text = open(sys.argv[1], encoding="utf-8").read()
meta = yaml.safe_load(re.match(r"^---\n(.*?)\n---", text, re.S).group(1))
assert meta["task_status"] == "done"
assert meta["origin"] == "user" and meta["priority"] == "medium"
assert meta["sensitivity"] == "internal" and meta["status"] == "open"
assert "folded description" in meta["description"]
assert any(e.get("kind") == "related" and e.get("path") == "knowledge/demo/note.md" for e in meta["relates_to"])
assert 'title: "Legacy task"' in text and "parent: ~" in text and "assignees: [ada]" in text
assert "# hand-written:" in text and "description: >-" in text
PY
  SPECIAL='Quote "here" \ backslash: colon'
  spec="$(PYTHONDONTWRITEBYTECODE=1 python3 "$TW" update --root "$FIX" --id "$TID_HAND" --title "$SPECIAL")"
  printf '%s\n' "$spec" | python3 -c 'import json,sys; o=json.load(sys.stdin); assert o["ok"] is True and o["title"]==sys.argv[1]' "$SPECIAL" \
    || fail "special title receipt ($label)"
  python3 - "$FIX" "$TID_HAND" "$SPECIAL" <<'PY' || fail "special title did not round-trip ($label)"
import re, sys, yaml
from pathlib import Path
fix, tid, title = sys.argv[1:]
hits = list(Path(fix, "tasks").rglob("*.md"))
found = None
for path in hits:
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---"):
        continue
    m = re.match(r"^---\n(.*?)\n---", text, re.S)
    if not m:
        continue
    meta = yaml.safe_load(m.group(1))
    if isinstance(meta, dict) and meta.get("task_id") == tid:
        found = meta
        break
assert found is not None, "renamed hand task not found"
assert found["title"] == title, found["title"]
PY
  rm -f "$FIX.hand.pristine" "$FIX.hand.before"
  # Review regressions (comment ids). Each one must fail closed or preserve bytes as noted.
  tw_run() {
    TW_NAME="$1"
    shift
    set +e
    PYTHONDONTWRITEBYTECODE=1 python3 "$TW" "$@" >"$FIX.tw.out" 2>"$FIX.tw.err"
    TW_RC=$?
    set -e
    if grep -q 'Traceback' "$FIX.tw.err"; then
      fail "tasks.py $TW_NAME printed a traceback ($label): $(cat "$FIX.tw.err")"
    fi
  }
  tw_ok() {
    tw_run "$@"
    if [[ "$TW_RC" -ne 0 ]]; then
      fail "tasks.py $TW_NAME failed rc=$TW_RC ($label): $(cat "$FIX.tw.out" "$FIX.tw.err")"
    fi
  }

  # 4312597554 / 4312597833: a case-only rename must not relocate the folder onto itself.
  TRIP_DIR="$FIX/tasks/${U_LIST}-trip"
  python3 - "$TRIP_DIR/photo.bin" <<'PY'
import sys
open(sys.argv[1], "wb").write(b"\xff\xfe\x00\x01not-utf8")
PY
  printf 'keep-notes\n' > "$TRIP_DIR/notes.txt"
  LIST_PAGE="$TRIP_DIR/${U_LIST}-trip.task-list.md"
  [[ -f "$LIST_PAGE" && -f "$TRIP_DIR/index.md" ]] || fail "trip list folder incomplete before case rename ($label)"
  tw_ok "4312597554 case rename" update --root "$FIX" --id "$TID_LIST" --title "TRIP"
  python3 - "$FIX.tw.out" <<'PY' || fail "4312597554 case rename receipt ($label)"
import json, sys
o = json.load(open(sys.argv[1]))
assert o["ok"] is True and o["title"] == "TRIP", o
assert o["path"].endswith("-trip.task-list.md") and "-trip-new" not in o["path"], o["path"]
PY
  [[ -f "$LIST_PAGE" ]] || fail "4312597554 case rename removed the list page ($label)"
  [[ -f "$TRIP_DIR/index.md" ]] || fail "4312597554 case rename deleted the list index ($label)"
  grep -Fq "generated_by: atlas-tasks" "$TRIP_DIR/index.md" || fail "4312597554 case rename lost the generated index ($label)"
  [[ "$(cat "$TRIP_DIR/notes.txt")" == "keep-notes" ]] || fail "4312597554 case rename lost notes ($label)"
  python3 - "$TRIP_DIR/photo.bin" <<'PY' || fail "4312597554 case rename lost attachment bytes ($label)"
import sys
assert open(sys.argv[1], "rb").read() == b"\xff\xfe\x00\x01not-utf8"
PY
  tw_ok "4312597554 resubmit title" update --root "$FIX" --id "$TID_LIST" --title "TRIP"
  [[ -f "$LIST_PAGE" && -f "$TRIP_DIR/index.md" && -f "$TRIP_DIR/notes.txt" && -f "$TRIP_DIR/photo.bin" ]] \
    || fail "4312597554 resubmit relocated the list folder onto itself ($label)"

  # Same folder, non-canonical list-page basename: rename the page only.
  ALIAS="$TRIP_DIR/${U_LIST}-alias.task-list.md"
  mv "$LIST_PAGE" "$ALIAS"
  tw_ok "4312597554 basename rename" update --root "$FIX" --id "$TID_LIST" --title "TRIP"
  [[ -f "$LIST_PAGE" ]] || fail "4312597554 basename-only rename did not restore the list page ($label)"
  [[ ! -e "$ALIAS" ]] || fail "4312597554 alias list page still present ($label)"
  [[ -d "$TRIP_DIR" && -f "$TRIP_DIR/index.md" && -f "$TRIP_DIR/notes.txt" ]] \
    || fail "4312597554 basename-only rename moved or deleted the folder ($label)"
  python3 - "$TRIP_DIR/photo.bin" <<'PY' || fail "4312597554 basename rename lost attachment ($label)"
import sys
assert open(sys.argv[1], "rb").read() == b"\xff\xfe\x00\x01not-utf8"
PY

  # 4312597605: reject an occupied destination folder before planning the move.
  tw_ok "4312597605 add dest list" add --root "$FIX" --kind task-list --title "Dest A"
  read -r DEST_ID DEST_ULID < <(python3 -c 'import json,sys; o=json.load(sys.stdin); print(o["task_id"], o["ulid"])' <"$FIX.tw.out")
  mkdir -p "$FIX/tasks/${DEST_ULID}-dest-b"
  printf 'secret\n' > "$FIX/tasks/${DEST_ULID}-dest-b/keep.txt"
  rc="$(assert_unchanged "4312597605 occupied list dest" update --root "$FIX" --id "$DEST_ID" --title "Dest B")"
  [[ "$rc" == "1" ]] || fail "4312597605 occupied list dest must exit 1, got $rc ($label)"
  grep -Fq "target path already exists" "$FIX.writer.out" || fail "4312597605 occupied dest error ($label): $(cat "$FIX.writer.out")"
  python3 - "$FIX.writer.out" <<'PY' || fail "4312597605 occupied dest receipt ($label)"
import json, sys
o = json.load(open(sys.argv[1]))
assert o["ok"] is False and "target path already exists" in o["error"], o
PY
  grep -q 'Traceback' "$FIX.writer.err" && fail "4312597605 occupied dest printed a traceback ($label)" || true
  [[ "$(cat "$FIX/tasks/${DEST_ULID}-dest-b/keep.txt")" == "secret" ]] || fail "4312597605 occupied dest clobbered keep.txt ($label)"
  rm -rf "$FIX/tasks/${DEST_ULID}-dest-b"

  # 4312597792 / 4312597833: one-pass longest rewrite; non-page files move as raw bytes.
  tw_ok "4312597792 prefix rename" update --root "$FIX" --id "$TID_LIST" --title "Trip new"
  python3 - "$FIX" "$U_LIST" <<'PY' || fail "4312597792 prefix rename broke links or attachments ($label)"
import sys
from pathlib import Path
fix, ulid = sys.argv[1:]
root = Path(fix)
old = root / "tasks" / f"{ulid}-trip"
new = root / "tasks" / f"{ulid}-trip-new"
assert not old.exists(), "old folder remains"
assert new.is_dir(), "new folder missing"
assert (new / "photo.bin").read_bytes() == b"\xff\xfe\x00\x01not-utf8"
assert (new / "notes.txt").read_text(encoding="utf-8") == "keep-notes\n"
assert (new / "index.md").is_file()
assert (new / f"{ulid}-trip-new.task-list.md").is_file()
blob = "\n".join(p.read_text(encoding="utf-8", errors="replace") for p in (root / "tasks").rglob("*.md"))
assert "trip-new-new" not in blob, "folder token rewritten twice"
assert "UnicodeDecodeError" not in blob
PY

  # 4312597692 / 4312597980: stabilize path edges on move; derived_blocked resolves them first.
  tw_ok "4312597692 add path blocker" add --root "$FIX" --title "Path blocker" --related-node "$RELATED" --body "$BODY"
  read -r BLOCK_ID BLOCK_ULID BLOCK_PATH < <(python3 -c 'import json,sys; o=json.load(sys.stdin); print(o["task_id"], o["ulid"], o["path"])' <"$FIX.tw.out")
  tw_ok "4312597692 add path waiter" add --root "$FIX" --title "Path waiter" --related-node "$RELATED" --body "$BODY" --depends-on "$BLOCK_ID"
  read -r WAIT_ID WAIT_ULID WAIT_PATH < <(python3 -c 'import json,sys; o=json.load(sys.stdin); assert o["derived_blocked"] is True; print(o["task_id"], o["ulid"], o["path"])' <"$FIX.tw.out")
  python3 - "$FIX" "$WAIT_PATH" "$BLOCK_PATH" "$WAIT_ID" "$BLOCK_ID" <<'PY' || fail "4312597692 could not rewrite edges to paths ($label)"
import re, sys
from pathlib import Path
fix, wait_rel, block_rel, wait_id, block_id = sys.argv[1:]
root = Path(fix)
def retarget(rel, old, new):
    path = root / rel
    text = path.read_text(encoding="utf-8")
    pat = re.compile(r'(path:\s*)(?:"' + re.escape(old) + r'"|' + re.escape(old) + r')')
    updated, n = pat.subn(lambda m: m.group(1) + new, text, count=1)
    if n != 1:
        raise SystemExit(f"path edge not rewritten in {rel}")
    path.write_text(updated, encoding="utf-8")
retarget(wait_rel, block_id, block_rel)
retarget(block_rel, wait_id, wait_rel)
PY
  tw_ok "4312597980 open path" update --root "$FIX" --id "$WAIT_ID" --status in_progress
  python3 -c 'import json,sys; o=json.load(open(sys.argv[1])); assert o["derived_blocked"] is True, o' "$FIX.tw.out" \
    || fail "4312597980 open path dependency must be derived_blocked ($label)"
  tw_ok "4312597980 blocker done" update --root "$FIX" --id "$BLOCK_ID" --status done
  tw_ok "4312597980 done path" update --root "$FIX" --id "$WAIT_ID" --status open
  python3 -c 'import json,sys; o=json.load(open(sys.argv[1])); assert o["derived_blocked"] is False, o' "$FIX.tw.out" \
    || fail "4312597980 done path dependency must not be derived_blocked ($label)"
  tw_ok "4312597980 blocker cancelled" update --root "$FIX" --id "$BLOCK_ID" --status cancelled
  tw_ok "4312597980 cancelled path" update --root "$FIX" --id "$WAIT_ID" --status in_progress
  python3 -c 'import json,sys; o=json.load(open(sys.argv[1])); assert o["derived_blocked"] is False, o' "$FIX.tw.out" \
    || fail "4312597980 cancelled path dependency must not be derived_blocked ($label)"
  tw_ok "4312597980 remote" add --root "$FIX" --title "Remote waiter" --related-node "$RELATED" --body "$BODY" \
    --depends-on "atlas://cross.example/tasks/01J8E3KBR8V6Z2B9T0V3V4Y5D4"
  python3 -c 'import json,sys; o=json.load(open(sys.argv[1])); assert o["ok"] is True and o["derived_blocked"] is True, o' "$FIX.tw.out" \
    || fail "4312597980 unresolved remote must be derived_blocked ($label)"
  tw_ok "4312597692 move blocker" update --root "$FIX" --id "$BLOCK_ID" --title "Path blocker moved"
  python3 - "$FIX" "$WAIT_PATH" "$BLOCK_ID" "$BLOCK_PATH" <<'PY' || fail "4312597692 path dependency not stabilized ($label)"
import re, sys, yaml
from pathlib import Path
fix, wait_rel, block_id, old_block = sys.argv[1:]
text = Path(fix, wait_rel).read_text(encoding="utf-8")
meta = yaml.safe_load(re.match(r"^---\n(.*?)\n---", text, re.S).group(1))
deps = [e.get("path") for e in meta.get("relates_to") or [] if isinstance(e, dict) and e.get("kind") == "dependency"]
assert block_id in deps, deps
assert old_block not in deps, deps
assert old_block not in text
PY
  tw_ok "4312597692 move waiter" update --root "$FIX" --id "$WAIT_ID" --title "Path waiter moved"
  python3 - "$FIX" "$WAIT_ID" "$WAIT_PATH" <<'PY' || fail "4312597692 path blocks edge not stabilized ($label)"
import re, sys, yaml
from pathlib import Path
fix, wait_id, old_wait = sys.argv[1:]
found = None
for path in Path(fix, "tasks").rglob("*.md"):
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---"):
        continue
    m = re.match(r"^---\n(.*?)\n---", text, re.S)
    if not m:
        continue
    meta = yaml.safe_load(m.group(1))
    if not isinstance(meta, dict):
        continue
    edges = meta.get("relates_to") or []
    if any(isinstance(e, dict) and e.get("kind") == "blocks" and e.get("path") == wait_id for e in edges):
        found = text
        break
assert found is not None, "blocks edge was not converted to a task URI"
assert old_wait not in found
PY

  # 4312597735: preserve CRLF. A status update and complete each change one line.
  tw_ok "4312597735 add crlf task" add --root "$FIX" --title "Crlf task" --related-node "$RELATED" --body "$BODY"
  read -r CRLF_ID CRLF_PATH < <(python3 -c 'import json,sys; o=json.load(sys.stdin); print(o["task_id"], o["path"])' <"$FIX.tw.out")
  python3 - "$FIX/$CRLF_PATH" <<'PY' || fail "4312597735 could not convert task to CRLF ($label)"
import sys
from pathlib import Path
path = Path(sys.argv[1])
raw = path.read_bytes()
if b"\r\n" in raw:
    raise SystemExit("task already uses CRLF")
path.write_bytes(raw.replace(b"\n", b"\r\n"))
PY
  cp "$FIX/$CRLF_PATH" "$FIX.crlf.before"
  tw_ok "4312597735 crlf status" update --root "$FIX" --id "$CRLF_ID" --status in_progress
  python3 - "$FIX.crlf.before" "$FIX/$CRLF_PATH" update <<'PY' || fail "4312597735 CRLF status diff ($label)"
import sys
before, after, what = sys.argv[1:]
a = open(before, "rb").read()
b = open(after, "rb").read()
if b"\n" in b.replace(b"\r\n", b""):
    raise SystemExit(f"{what} introduced a bare LF")
a_lines, b_lines = a.split(b"\r\n"), b.split(b"\r\n")
if len(a_lines) != len(b_lines):
    raise SystemExit(f"{what} changed line count {len(a_lines)} -> {len(b_lines)}")
changed = [i for i, (x, y) in enumerate(zip(a_lines, b_lines)) if x != y]
if len(changed) != 1 or b"task_status" not in a_lines[changed[0]]:
    raise SystemExit(f"{what} diff lines {changed}")
PY
  cp "$FIX/$CRLF_PATH" "$FIX.crlf.before"
  tw_ok "4312597735 crlf complete" complete --root "$FIX" --id "$CRLF_ID"
  python3 - "$FIX.crlf.before" "$FIX/$CRLF_PATH" complete <<'PY' || fail "4312597735 CRLF complete diff ($label)"
import sys
before, after, what = sys.argv[1:]
a = open(before, "rb").read()
b = open(after, "rb").read()
if b"\n" in b.replace(b"\r\n", b""):
    raise SystemExit(f"{what} introduced a bare LF")
a_lines, b_lines = a.split(b"\r\n"), b.split(b"\r\n")
if len(a_lines) != len(b_lines):
    raise SystemExit(f"{what} changed line count {len(a_lines)} -> {len(b_lines)}")
changed = [i for i, (x, y) in enumerate(zip(a_lines, b_lines)) if x != y]
if len(changed) != 1 or b"task_status" not in a_lines[changed[0]] or b"done" not in b_lines[changed[0]]:
    raise SystemExit(f"{what} diff lines {changed}")
PY
  python3 - "$FIX/$CRLF_PATH" <<'PY'
import sys
from pathlib import Path
path = Path(sys.argv[1])
path.write_bytes(path.read_bytes().replace(b"\r\n", b"\n"))
PY
  rm -f "$FIX.crlf.before"

  # 4312597884: existing tasks require only mandatory fields. Do not add optional keys.
  MIN_ULID="01J8E3KDT0X8B4D1W2X5Y6Z7F5"
  MIN_ID="atlas://${AID}/tasks/${MIN_ULID}"
  python3 - "$FIX" "$MIN_ID" "$MIN_ULID" <<'PY' || fail "4312597884 could not install minimal task ($label)"
import re, sys
from pathlib import Path
fix, uri, ulid = sys.argv[1:]
root = Path(fix)
idx = root / "tasks" / "index.md"
text = idx.read_text(encoding="utf-8")
m = re.match(r"^---\n(.*?)\n---", text, re.S)
if not m or not re.search(r"^tasks:\n", m.group(1), re.M):
    raise SystemExit("root tasks block missing")
inner = re.sub(r"^tasks:\n", "tasks:\n  - %s\n" % uri, m.group(1), count=1, flags=re.M)
idx.write_text("---\n" + inner + "\n---" + text[m.end():], encoding="utf-8")
(root / "tasks" / f"{ulid}-minimal.md").write_text(
    "---\n"
    "type: task\n"
    "title: Minimal\n"
    'created: "2026-10-01"\n'
    f"task_id: {uri}\n"
    "task_status: open\n"
    "body_path: knowledge/demo/todo-demo.md\n"
    "---\n"
    "Pointer only. Full prose lives in the colocated body page; this page stays a short pointer.\n",
    encoding="utf-8",
)
PY
  tw_ok "4312597884 minimal status" update --root "$FIX" --id "$MIN_ID" --status in_progress
  python3 - "$FIX/tasks/${MIN_ULID}-minimal.md" in_progress <<'PY' || fail "4312597884 status added optional keys ($label)"
import re, sys, yaml
text = open(sys.argv[1], encoding="utf-8").read()
meta = yaml.safe_load(re.match(r"^---\n(.*?)\n---", text, re.S).group(1))
for key in ("assignees", "parent", "sub_tasks", "relates_to", "related_node", "task_list"):
    if key in meta:
        raise SystemExit(f"added {key}")
assert meta["task_status"] == sys.argv[2], meta["task_status"]
PY
  tw_ok "4312597884 minimal complete" complete --root "$FIX" --id "$MIN_ID"
  python3 - "$FIX/tasks/${MIN_ULID}-minimal.md" done <<'PY' || fail "4312597884 complete added optional keys ($label)"
import re, sys, yaml
text = open(sys.argv[1], encoding="utf-8").read()
meta = yaml.safe_load(re.match(r"^---\n(.*?)\n---", text, re.S).group(1))
for key in ("assignees", "parent", "sub_tasks", "relates_to", "related_node", "task_list"):
    if key in meta:
        raise SystemExit(f"added {key}")
assert meta["task_status"] == sys.argv[2], meta["task_status"]
PY

  # 4312597934: when related_node is present, body_path must sit beside it after the write.
  mkdir -p "$FIX/knowledge/side"
  cat > "$FIX/knowledge/side/index.md" <<'MD'
---
type: document
title: Side knowledge folder
created: "2026-10-01"
---
Index for the side knowledge folder used by colocation checks in the writer smoke.
MD
  cat > "$FIX/knowledge/side/note.md" <<'MD'
---
type: document
title: Side note
created: "2026-10-01"
---
Related knowledge node in a different folder from the demo note, for colocation checks.
MD
  cat > "$FIX/knowledge/side/body.md" <<'MD'
---
type: document
title: Side body
created: "2026-10-01"
---
Colocated body prose in the side folder. Compile accepts this page beside the side note.
MD
  before="$(hash_tree "$FIX")"
  tw_run "4312597934 mismatched add" add --root "$FIX" --title "Bad colo" \
    --related-node "$RELATED" --body-path "knowledge/side/body.md"
  after="$(hash_tree "$FIX")"
  [[ "$TW_RC" -ne 0 && "$before" == "$after" ]] || fail "4312597934 mismatched add wrote or succeeded ($label)"
  grep -Fq "beside" "$FIX.tw.out" || fail "4312597934 mismatched add error ($label): $(cat "$FIX.tw.out")"
  before="$(hash_tree "$FIX")"
  tw_run "4312597934 directory mismatch" add --root "$FIX" --title "Bad dir colo" \
    --related-node "knowledge/side" --body-path "knowledge/demo/todo-demo.md"
  after="$(hash_tree "$FIX")"
  [[ "$TW_RC" -ne 0 && "$before" == "$after" ]] || fail "4312597934 directory mismatch wrote or succeeded ($label)"
  grep -Fq "beside" "$FIX.tw.out" || fail "4312597934 directory mismatch error ($label): $(cat "$FIX.tw.out")"
  tw_ok "4312597934 directory match" add --root "$FIX" --title "Dir colo" \
    --related-node "knowledge/side" --body-path "knowledge/side/body.md"
  tw_ok "4312597934 add colo task" add --root "$FIX" --title "Colo task" --related-node "$RELATED" --body "$BODY"
  read -r COLO_ID COLO_PATH < <(python3 -c 'import json,sys; o=json.load(sys.stdin); print(o["task_id"], o["path"])' <"$FIX.tw.out")
  rc="$(assert_unchanged "4312597934 body elsewhere" update --root "$FIX" --id "$COLO_ID" --body-path "knowledge/side/body.md")"
  [[ "$rc" == "1" ]] || fail "4312597934 body update must exit 1, got $rc ($label)"
  grep -Fq "beside" "$FIX.writer.out" || fail "4312597934 body update error ($label): $(cat "$FIX.writer.out")"
  rc="$(assert_unchanged "4312597934 node elsewhere" update --root "$FIX" --id "$COLO_ID" --related-node "knowledge/side/note.md")"
  [[ "$rc" == "1" ]] || fail "4312597934 related_node update must exit 1, got $rc ($label)"
  grep -Fq "beside" "$FIX.writer.out" || fail "4312597934 related_node update error ($label): $(cat "$FIX.writer.out")"
  tw_ok "4312597934 same directory" update --root "$FIX" --id "$COLO_ID" \
    --related-node "knowledge/side/note.md" --body-path "knowledge/side/body.md"
  python3 - "$FIX/$COLO_PATH" <<'PY' || fail "4312597934 same-directory update did not stick ($label)"
import re, sys, yaml
meta = yaml.safe_load(re.match(r"^---\n(.*?)\n---", open(sys.argv[1], encoding="utf-8").read(), re.S).group(1))
assert meta["related_node"] == "knowledge/side/note.md", meta.get("related_node")
assert meta["body_path"] == "knowledge/side/body.md", meta.get("body_path")
PY

  # 4312597647: exclusive lock around the whole transaction; dry-run may share the lock.
  hold_tasks_lock() {
    LOCK_MODE="$1"
    READY="$FIX.lock.ready"
    RELEASE="$FIX.lock.release"
    rm -f "$READY" "$RELEASE"
    python3 - "$FIX/tasks" "$READY" "$RELEASE" "$LOCK_MODE" >"$FIX.lock.holder.out" 2>"$FIX.lock.holder.err" <<'PY' &
import fcntl, os, sys, time
tasks, ready, release, mode = sys.argv[1:]
flags = os.O_RDONLY | os.O_DIRECTORY
if hasattr(os, "O_NOFOLLOW"):
    flags |= os.O_NOFOLLOW
fd = os.open(tasks, flags)
fcntl.flock(fd, fcntl.LOCK_EX if mode == "ex" else fcntl.LOCK_SH)
with open(ready, "w", encoding="utf-8") as fh:
    fh.write("locked\n")
    fh.flush()
deadline = time.time() + 25
while not os.path.exists(release) and time.time() < deadline:
    time.sleep(0.05)
fcntl.flock(fd, fcntl.LOCK_UN)
os.close(fd)
PY
    holder=$!
    ready=0
    for _ in $(seq 1 100); do
      if [[ -f "$READY" ]]; then ready=1; break; fi
      sleep 0.05
    done
    if [[ "$ready" != 1 ]]; then
      kill "$holder" 2>/dev/null || true
      wait "$holder" 2>/dev/null || true
      fail "4312597647 lock holder ($LOCK_MODE) did not start ($label): $(cat "$FIX.lock.holder.err" 2>/dev/null || true)"
    fi
  }
  release_tasks_lock() {
    echo go > "$RELEASE"
    set +e
    wait "$holder"
    set -e
  }
  hold_tasks_lock sh
  before="$(hash_tree "$FIX")"
  set +e
  timeout 10 env PYTHONDONTWRITEBYTECODE=1 python3 "$TW" add --root "$FIX" --title "Shared dry" \
    --related-node "$RELATED" --body "$BODY" --dry-run >"$FIX.shared.out" 2>"$FIX.shared.err"
  shared_rc=$?
  set -e
  after="$(hash_tree "$FIX")"
  if [[ "$shared_rc" -ne 0 || "$before" != "$after" ]]; then
    release_tasks_lock
    fail "4312597647 dry-run did not finish under a shared lock rc=$shared_rc ($label): $(cat "$FIX.shared.out" "$FIX.shared.err")"
  fi
  python3 -c 'import json,sys; o=json.load(open(sys.argv[1])); assert o["ok"] is True and o["dry_run"] is True' "$FIX.shared.out" \
    || { release_tasks_lock; fail "4312597647 shared dry-run receipt ($label)"; }
  set +e
  PYTHONDONTWRITEBYTECODE=1 python3 "$TW" add --root "$FIX" --title "Locked add" \
    --related-node "$RELATED" --body "$BODY" >"$FIX.lock.add.out" 2>"$FIX.lock.add.err" &
  add_pid=$!
  set -e
  sleep 1.5
  if ! kill -0 "$add_pid" 2>/dev/null; then
    release_tasks_lock
    fail "4312597647 add finished while a shared lock was held ($label): $(cat "$FIX.lock.add.out" "$FIX.lock.add.err")"
  fi
  echo go > "$RELEASE"
  waited=0
  for _ in $(seq 1 150); do
    if ! kill -0 "$add_pid" 2>/dev/null; then waited=1; break; fi
    sleep 0.1
  done
  if [[ "$waited" != 1 ]]; then
    kill "$add_pid" 2>/dev/null || true
    wait "$add_pid" 2>/dev/null || true
    wait "$holder" 2>/dev/null || true
    fail "4312597647 add stayed blocked after the shared lock was released ($label)"
  fi
  set +e
  wait "$add_pid"
  add_rc=$?
  wait "$holder"
  set -e
  [[ "$add_rc" -eq 0 ]] || fail "4312597647 add failed after shared unlock ($label): $(cat "$FIX.lock.add.out" "$FIX.lock.add.err")"
  hold_tasks_lock ex
  set +e
  PYTHONDONTWRITEBYTECODE=1 python3 "$TW" add --root "$FIX" --title "Exclusive add" \
    --related-node "$RELATED" --body "$BODY" >"$FIX.lock.add.out" 2>"$FIX.lock.add.err" &
  add_pid=$!
  set -e
  sleep 1.5
  if ! kill -0 "$add_pid" 2>/dev/null; then
    release_tasks_lock
    fail "4312597647 add finished while an exclusive lock was held ($label): $(cat "$FIX.lock.add.out" "$FIX.lock.add.err")"
  fi
  echo go > "$RELEASE"
  waited=0
  for _ in $(seq 1 150); do
    if ! kill -0 "$add_pid" 2>/dev/null; then waited=1; break; fi
    sleep 0.1
  done
  if [[ "$waited" != 1 ]]; then
    kill "$add_pid" 2>/dev/null || true
    wait "$add_pid" 2>/dev/null || true
    wait "$holder" 2>/dev/null || true
    fail "4312597647 add stayed blocked after the exclusive lock was released ($label)"
  fi
  set +e
  wait "$add_pid"
  add_rc=$?
  wait "$holder"
  set -e
  [[ "$add_rc" -eq 0 ]] || fail "4312597647 add failed after exclusive unlock ($label): $(cat "$FIX.lock.add.out" "$FIX.lock.add.err")"
  python3 -c 'import json,sys; o=json.load(open(sys.argv[1])); assert o["ok"] is True and o["title"]=="Exclusive add"' "$FIX.lock.add.out" \
    || fail "4312597647 exclusive add receipt ($label)"

  set +e
  PYTHONDONTWRITEBYTECODE=1 python3 "$TW" add --root "$FIX" --title "Race one" \
    --related-node "$RELATED" --body "$BODY" >"$FIX.race1.out" 2>"$FIX.race1.err" &
  race1=$!
  PYTHONDONTWRITEBYTECODE=1 python3 "$TW" add --root "$FIX" --title "Race two" \
    --related-node "$RELATED" --body "$BODY" >"$FIX.race2.out" 2>"$FIX.race2.err" &
  race2=$!
  set -e
  waited=0
  for _ in $(seq 1 200); do
    if ! kill -0 "$race1" 2>/dev/null && ! kill -0 "$race2" 2>/dev/null; then waited=1; break; fi
    sleep 0.1
  done
  if [[ "$waited" != 1 ]]; then
    kill "$race1" 2>/dev/null || true
    kill "$race2" 2>/dev/null || true
    wait "$race1" 2>/dev/null || true
    wait "$race2" 2>/dev/null || true
    fail "4312597647 parallel adds did not finish ($label)"
  fi
  set +e
  wait "$race1"
  race1_rc=$?
  wait "$race2"
  race2_rc=$?
  set -e
  [[ "$race1_rc" -eq 0 && "$race2_rc" -eq 0 ]] \
    || fail "4312597647 parallel adds rc=$race1_rc/$race2_rc ($label): $(cat "$FIX.race1.out" "$FIX.race1.err" "$FIX.race2.out" "$FIX.race2.err")"
  python3 - "$FIX" "$FIX.race1.out" "$FIX.race2.out" <<'PY' || fail "4312597647 parallel add lost a task ($label)"
import json, re, sys, yaml
from pathlib import Path
fix, a, b = sys.argv[1:]
ids = [json.load(open(a))["task_id"], json.load(open(b))["task_id"]]
text = Path(fix, "tasks/index.md").read_text(encoding="utf-8")
meta = yaml.safe_load(re.match(r"^---\n(.*?)\n---", text, re.S).group(1))
for tid in ids:
    assert tid in meta["tasks"], tid
PY

  # Stale snapshot, temp cleanup, and unexpected errors stay inside the fixture root.
  python3 - "$TW" "$FIX" <<'PY' || fail "4312597647/4312598014 writer internals ($label)"
import importlib.util, io, json, os, sys
from pathlib import Path
tw, fix = sys.argv[1:]
root = Path(fix)
spec = importlib.util.spec_from_file_location("tasks_writer_regress", tw)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
store = mod.load_store(root)
idx = root / "tasks" / "index.md"
original = idx.read_bytes()
try:
    idx.write_bytes(original + b"\n")
    st = idx.stat()
    os.utime(idx, ns=(st.st_atime_ns, st.st_mtime_ns + 1_000_000))
    try:
        mod.assert_store_unchanged(store, [])
    except mod.Fail as exc:
        if "store changed during write" not in exc.message:
            raise SystemExit(f"unexpected stale error: {exc.message}")
    else:
        raise SystemExit("stale store was accepted")
finally:
    idx.write_bytes(original)

def temps():
    return list(root.rglob(".tasks-*.tmp"))

real_write = os.write
def boom_write(fd, data):
    raise OSError("disk")
os.write = boom_write
try:
    try:
        mod.atomic_write(root, "tasks/probe-write.md", b"hi")
    except OSError:
        pass
    else:
        raise SystemExit("os.write failure did not propagate")
finally:
    os.write = real_write
if temps() or (root / "tasks/probe-write.md").exists():
    raise SystemExit(f"temp left after os.write failure: {temps()}")

real_fsync = os.fsync
def boom_fsync(fd):
    raise OSError("fsync")
os.fsync = boom_fsync
try:
    try:
        mod.atomic_write(root, "tasks/probe-fsync.md", b"hi")
    except OSError:
        pass
    else:
        raise SystemExit("os.fsync failure did not propagate")
finally:
    os.fsync = real_fsync
if temps() or (root / "tasks/probe-fsync.md").exists():
    raise SystemExit(f"temp left after os.fsync failure: {temps()}")

real_replace = os.replace
def boom_replace(src, dst):
    raise OSError("replace")
os.replace = boom_replace
try:
    try:
        mod.atomic_write(root, "tasks/probe-replace.md", b"hi")
    except OSError:
        pass
    else:
        raise SystemExit("os.replace failure did not propagate")
finally:
    os.replace = real_replace
if temps() or (root / "tasks/probe-replace.md").exists():
    raise SystemExit(f"temp left after os.replace failure: {temps()}")

def boom_load(_root):
    raise RuntimeError("boom")
mod.load_store = boom_load
buf, err = io.StringIO(), io.StringIO()
old, old_e = sys.stdout, sys.stderr
sys.stdout, sys.stderr = buf, err
try:
    rc = mod.main(["complete", "--root", str(root), "--id", "01J8E3KDT0X8B4D1W2X5Y6Z7F5"])
finally:
    sys.stdout, sys.stderr = old, old_e
if rc != 1:
    raise SystemExit(f"unexpected error rc={rc} out={buf.getvalue()!r} err={err.getvalue()!r}")
if "Traceback" in err.getvalue() or err.getvalue().strip():
    raise SystemExit(f"unexpected error printed a traceback: {err.getvalue()!r}")
receipt = json.loads(buf.getvalue())
if receipt.get("ok") is not False or receipt.get("error") != "fail-closed: unexpected error":
    raise SystemExit(f"unexpected error receipt: {receipt}")
print("writer internals ok")
PY

  # 4312989017: rewrite relative folder links and list-page basenames in the same pass.
  tw_ok "4312989017 add link list" add --root "$FIX" --kind task-list --title "Link list"
  read -r LINK_ID LINK_ULID LINK_PATH < <(python3 -c 'import json,sys; o=json.load(open(sys.argv[1])); print(o["task_id"], o["ulid"], o["path"])' "$FIX.tw.out")
  [[ -n "$LINK_ID" && "$LINK_PATH" == "tasks/${LINK_ULID}-link-list/${LINK_ULID}-link-list.task-list.md" ]] \
    || fail "4312989017 link list receipt ($label): $(cat "$FIX.tw.out")"
  python3 - "$FIX/tasks/index.md" "$LINK_ULID" <<'PY' || fail "4312989017 could not inject relative links ($label)"
import sys
path, ulid = sys.argv[1:]
text = open(path, encoding="utf-8").read()
if not text.endswith("\n"):
    text += "\n"
text += "[Trip](<%s-link-list/%s-link-list.task-list.md>)\nAlso %s-link-list.task-list.md\n" % (ulid, ulid, ulid)
open(path, "w", encoding="utf-8").write(text)
PY
  tw_ok "4312989017 rename link list" update --root "$FIX" --id "$LINK_ID" --title "Link pack"
  python3 - "$FIX/tasks/index.md" "$LINK_ULID" <<'PY' || fail "4312989017 relative links not rewritten ($label)"
import sys
text = open(sys.argv[1], encoding="utf-8").read()
ulid = sys.argv[2]
old = "%s-link-list" % ulid
new = "%s-link-pack" % ulid
if "[Trip](<%s/%s.task-list.md>)" % (new, new) not in text:
    raise SystemExit("root relative folder link was not rewritten")
if "Also %s.task-list.md" % new not in text:
    raise SystemExit("root list-page basename was not rewritten")
if old in text:
    raise SystemExit("old relative folder remains in the root body")
PY
  [[ ! -e "$FIX/tasks/${LINK_ULID}-link-list" ]] || fail "4312989017 old link folder remains ($label)"
  [[ -f "$FIX/tasks/${LINK_ULID}-link-pack/${LINK_ULID}-link-pack.task-list.md" ]] \
    || fail "4312989017 renamed link list missing ($label)"
  tw_ok "4312989017 add nested link" add --root "$FIX" --kind task-list --title "Nested link" --task-list "$LINK_ID"
  read -r NEST_ID NEST_ULID NEST_PATH < <(python3 -c 'import json,sys; o=json.load(open(sys.argv[1])); print(o["task_id"], o["ulid"], o["path"])' "$FIX.tw.out")
  [[ "$NEST_PATH" == "tasks/${LINK_ULID}-link-pack/${NEST_ULID}-nested-link/${NEST_ULID}-nested-link.task-list.md" ]] \
    || fail "4312989017 nested path ($NEST_PATH)"
  python3 - "$FIX/tasks/index.md" "$FIX/tasks/${LINK_ULID}-link-pack/${LINK_ULID}-link-pack.task-list.md" \
    "$LINK_ULID" "$NEST_ULID" <<'PY' || fail "4312989017 could not inject nested relative links ($label)"
import sys
root_p, parent_p, link_ulid, nest = sys.argv[1:]
root = open(root_p, encoding="utf-8").read()
parent = open(parent_p, encoding="utf-8").read()
if not root.endswith("\n"):
    root += "\n"
if not parent.endswith("\n"):
    parent += "\n"
root += "[Trip](<%s-link-pack/%s-nested-link/%s-nested-link.task-list.md>)\n" % (link_ulid, nest, nest)
parent += "[Trip](<%s-nested-link/%s-nested-link.task-list.md>)\nAlso %s-nested-link.task-list.md\n" % (nest, nest, nest)
open(root_p, "w", encoding="utf-8").write(root)
open(parent_p, "w", encoding="utf-8").write(parent)
PY
  tw_ok "4312989017 rename nested link" update --root "$FIX" --id "$NEST_ID" --title "Nested pack"
  python3 - "$FIX/tasks/index.md" "$FIX/tasks/${LINK_ULID}-link-pack/${LINK_ULID}-link-pack.task-list.md" \
    "$LINK_ULID" "$NEST_ULID" <<'PY' || fail "4312989017 nested relative links not rewritten ($label)"
import sys
root = open(sys.argv[1], encoding="utf-8").read()
parent = open(sys.argv[2], encoding="utf-8").read()
link_ulid, nest = sys.argv[3:]
old = "%s-nested-link" % nest
new_root = "[Trip](<%s-link-pack/%s-nested-pack/%s-nested-pack.task-list.md>)" % (link_ulid, nest, nest)
new_parent = "[Trip](<%s-nested-pack/%s-nested-pack.task-list.md>)" % (nest, nest)
if new_root not in root:
    raise SystemExit("root-relative nested link was not rewritten")
if new_parent not in parent or "Also %s-nested-pack.task-list.md" % nest not in parent:
    raise SystemExit("parent-relative nested link was not rewritten")
if old in root or old in parent:
    raise SystemExit("old nested folder token remains")
PY
  [[ ! -e "$FIX/tasks/${LINK_ULID}-link-pack/${NEST_ULID}-nested-link" ]] \
    || fail "4312989017 old nested folder remains ($label)"
  # The rewrite is asserted above. Drop the injected links so compile does not
  # treat the angle-bracket destinations as store paths.
  python3 - "$FIX/tasks/index.md" "$FIX/tasks/${LINK_ULID}-link-pack/${LINK_ULID}-link-pack.task-list.md" <<'PY' \
    || fail "4312989017 could not drop injected links ($label)"
import sys
for path in sys.argv[1:]:
    lines = open(path, encoding="utf-8").read().splitlines(keepends=True)
    kept = [line for line in lines if not line.startswith("[Trip](") and not line.startswith("Also ")]
    open(path, "w", encoding="utf-8").write("".join(kept))
PY
  pass "4312989017 relative rename links ($label)"

  # 4312988824: create uses umask; update keeps the destination mode; move keeps the source mode.
  (
    umask 027
    tw_ok "4312988824 umask create" add --root "$FIX" --title "Umask task" \
      --related-node "$RELATED" --body "$BODY"
  ) || fail "4312988824 umask create failed ($label)"
  read -r UMASK_ID UMASK_PATH < <(python3 -c 'import json,sys; o=json.load(open(sys.argv[1])); print(o["task_id"], o["path"])' "$FIX.tw.out")
  python3 - "$FIX/$UMASK_PATH" <<'PY' || fail "4312988824 new file mode ($label)"
import os, stat, sys
mode = stat.S_IMODE(os.stat(sys.argv[1]).st_mode)
if mode != 0o640:
    raise SystemExit("create mode %s, expected 0o640" % oct(mode))
PY
  chmod 604 "$FIX/$UMASK_PATH"
  tw_ok "4312988824 status keeps mode" update --root "$FIX" --id "$UMASK_ID" --status in_progress
  python3 - "$FIX/$UMASK_PATH" <<'PY' || fail "4312988824 update did not keep destination mode ($label)"
import os, stat, sys
mode = stat.S_IMODE(os.stat(sys.argv[1]).st_mode)
if mode != 0o604:
    raise SystemExit("update mode %s, expected 0o604" % oct(mode))
PY
  tw_ok "4312988824 add exec list" add --root "$FIX" --kind task-list --title "Exec list"
  read -r EXEC_ID EXEC_ULID < <(python3 -c 'import json,sys; o=json.load(open(sys.argv[1])); print(o["task_id"], o["ulid"])' "$FIX.tw.out")
  EXEC_DIR="$FIX/tasks/${EXEC_ULID}-exec-list"
  printf '#!/bin/sh\necho ok\n' > "$EXEC_DIR/run.sh"
  chmod 755 "$EXEC_DIR/run.sh"
  chmod 640 "$EXEC_DIR/${EXEC_ULID}-exec-list.task-list.md"
  tw_ok "4312988824 rename exec list" update --root "$FIX" --id "$EXEC_ID" --title "Exec renamed"
  python3 - "$FIX/tasks/${EXEC_ULID}-exec-renamed/run.sh" \
    "$FIX/tasks/${EXEC_ULID}-exec-renamed/${EXEC_ULID}-exec-renamed.task-list.md" <<'PY' \
    || fail "4312988824 move did not keep source mode ($label)"
import os, stat, sys
aux = stat.S_IMODE(os.stat(sys.argv[1]).st_mode)
page = stat.S_IMODE(os.stat(sys.argv[2]).st_mode)
if aux != 0o755:
    raise SystemExit("aux mode %s, expected 0o755" % oct(aux))
if page != 0o640:
    raise SystemExit("moved page mode %s, expected 0o640" % oct(page))
PY
  [[ ! -e "$EXEC_DIR" ]] || fail "4312988824 old exec folder remains ($label)"
  pass "4312988824 file modes preserved ($label)"

  # 4312988978: remove only an isolated membership entry; otherwise tell the caller to edit manually.
  tw_ok "4312988978 add mention list" add --root "$FIX" --kind task-list --title "Mention list"
  read -r MEN_LIST_ID MEN_LIST_ULID MEN_LIST_PATH < <(python3 -c 'import json,sys; o=json.load(open(sys.argv[1])); print(o["task_id"], o["ulid"], o["path"])' "$FIX.tw.out")
  tw_ok "4312988978 add clean member" add --root "$FIX" --title "Clean member" \
    --related-node "$RELATED" --body "$BODY" --task-list "$MEN_LIST_ID"
  read -r CLEAN_ID < <(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["task_id"])' "$FIX.tw.out")
  printf '\nPacking notes stay.\n' >> "$FIX/$MEN_LIST_PATH"
  tw_ok "4312988978 clear isolated" update --root "$FIX" --id "$CLEAN_ID" --clear-task-list
  python3 - "$FIX/$MEN_LIST_PATH" "$CLEAN_ID" <<'PY' || fail "4312988978 isolated removal ($label)"
import re, sys, yaml
text = open(sys.argv[1], encoding="utf-8").read()
uri = sys.argv[2]
if uri in text:
    raise SystemExit("member URI still in the list body")
if "Packing notes stay." not in text:
    raise SystemExit("unrelated prose was removed")
meta = yaml.safe_load(re.match(r"^---\n(.*?)\n---", text, re.S).group(1))
if uri in (meta.get("tasks") or []):
    raise SystemExit("member still in frontmatter")
PY
  tw_ok "4312988978 add mixed member" add --root "$FIX" --title "Mixed member" \
    --related-node "$RELATED" --body "$BODY" --task-list "$MEN_LIST_ID"
  read -r MIX_ID < <(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["task_id"])' "$FIX.tw.out")
  tw_ok "4312988978 add other member" add --root "$FIX" --title "Other member" \
    --related-node "$RELATED" --body "$BODY" --task-list "$MEN_LIST_ID"
  read -r OTHER_ID < <(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["task_id"])' "$FIX.tw.out")
  printf '\n- Remember %s and also %s before departure.\n' "$MIX_ID" "$OTHER_ID" >> "$FIX/$MEN_LIST_PATH"
  before="$(hash_tree "$FIX")"
  tw_run "4312988978 unsafe mention" update --root "$FIX" --id "$MIX_ID" --clear-task-list
  after="$(hash_tree "$FIX")"
  [[ "$TW_RC" -ne 0 ]] || fail "4312988978 unsafe mention was accepted ($label)"
  [[ "$before" == "$after" ]] || fail "4312988978 unsafe mention changed the tree ($label)"
  grep -Fq "edit manually" "$FIX.tw.out" || fail "4312988978 missing edit manually ($label): $(cat "$FIX.tw.out")"
  python3 - "$FIX/$MEN_LIST_PATH" <<'PY' || fail "4312988978 could not drop the unsafe line ($label)"
import sys
path = sys.argv[1]
text = open(path, encoding="utf-8").read()
kept = [line for line in text.splitlines(keepends=True) if "before departure" not in line]
open(path, "w", encoding="utf-8").write("".join(kept))
PY
  pass "4312988978 isolated membership lines ($label)"

  # 4312988939: a reachable page whose declared type disagrees with its filename must fail closed.
  cp "$FIX/tasks/index.md" "$FIX.index.type.bak"
  BAD_DOC="01J8E3KDT0X8B4D1W2X5Y6Z7F6"
  BAD_DOC_ID="atlas://${AID}/tasks/${BAD_DOC}"
  python3 - "$FIX" "$BAD_DOC_ID" "$BAD_DOC" <<'PY' || fail "4312988939 could not install document member ($label)"
import re, sys
from pathlib import Path
fix, uri, ulid = sys.argv[1:]
root = Path(fix)
idx = root / "tasks" / "index.md"
text = idx.read_text(encoding="utf-8")
m = re.match(r"^---\n(.*?)\n---", text, re.S)
if not m or not re.search(r"^tasks:\n", m.group(1), re.M):
    raise SystemExit("root tasks block missing")
inner = re.sub(r"^tasks:\n", "tasks:\n  - %s\n" % uri, m.group(1), count=1, flags=re.M)
idx.write_text("---\n" + inner + "\n---" + text[m.end():], encoding="utf-8")
(root / "tasks" / ("%s-doc.md" % ulid)).write_text(
    "---\ntype: document\ntitle: Not a task\ntask_id: %s\n---\n" % uri,
    encoding="utf-8",
)
PY
  before="$(hash_tree "$FIX")"
  tw_run "4312988939 document member" update --root "$FIX" --id "$TID_DEMO" --title "Demo typecheck"
  after="$(hash_tree "$FIX")"
  [[ "$TW_RC" -ne 0 ]] || fail "4312988939 document member was accepted ($label)"
  [[ "$before" == "$after" ]] || fail "4312988939 document member changed the tree ($label)"
  grep -Fq "declared type does not match filename" "$FIX.tw.out" \
    || fail "4312988939 document member error ($label): $(cat "$FIX.tw.out" "$FIX.tw.err")"
  cp "$FIX.index.type.bak" "$FIX/tasks/index.md"
  rm -f "$FIX/tasks/${BAD_DOC}-doc.md"
  BAD_LIST="01J8E3KDT0X8B4D1W2X5Y6Z7F7"
  BAD_LIST_ID="atlas://${AID}/tasks/${BAD_LIST}"
  python3 - "$FIX" "$BAD_LIST_ID" "$BAD_LIST" <<'PY' || fail "4312988939 could not install misdeclared list ($label)"
import re, sys
from pathlib import Path
fix, uri, ulid = sys.argv[1:]
root = Path(fix)
idx = root / "tasks" / "index.md"
text = idx.read_text(encoding="utf-8")
m = re.match(r"^---\n(.*?)\n---", text, re.S)
if not m or not re.search(r"^tasks:\n", m.group(1), re.M):
    raise SystemExit("root tasks block missing")
inner = re.sub(r"^tasks:\n", "tasks:\n  - %s\n" % uri, m.group(1), count=1, flags=re.M)
idx.write_text("---\n" + inner + "\n---" + text[m.end():], encoding="utf-8")
folder = root / "tasks" / ("%s-badlist" % ulid)
folder.mkdir()
(folder / ("%s-badlist.task-list.md" % ulid)).write_text(
    "---\ntype: task\ntitle: Bad list\ntask_id: %s\ntasks: []\n---\n" % uri,
    encoding="utf-8",
)
PY
  before="$(hash_tree "$FIX")"
  tw_run "4312988939 misdeclared list" add --root "$FIX" --title "Should not land" \
    --related-node "$RELATED" --body "$BODY" --task-list "$BAD_LIST_ID"
  after="$(hash_tree "$FIX")"
  [[ "$TW_RC" -ne 0 ]] || fail "4312988939 misdeclared list was accepted ($label)"
  [[ "$before" == "$after" ]] || fail "4312988939 misdeclared list changed the tree ($label)"
  grep -Fq "declared type does not match filename" "$FIX.tw.out" \
    || fail "4312988939 misdeclared list error ($label): $(cat "$FIX.tw.out" "$FIX.tw.err")"
  cp "$FIX.index.type.bak" "$FIX/tasks/index.md"
  rm -rf "$FIX/tasks/${BAD_LIST}-badlist"
  rm -f "$FIX.index.type.bak"
  tw_ok "4312988939 store loads" update --root "$FIX" --id "$TID_DEMO" --status open --dry-run
  pass "4312988939 declared type matches filename ($label)"

  # 4312988869 move destinations, 4312988911 index reads, 4312989062 created dirs, mode rollback.
  python3 - "$TW" "$LFI" "$FIX" "$MEN_LIST_PATH" "$MIX_ID" <<'PY' || fail "4312988824/4312988869/4312988911/4312989062 regressions ($label)"
import importlib.util, io, json, os, stat, sys
from pathlib import Path

tw, lfi_path, fix, list_rel, mix_id = sys.argv[1:]
root = Path(fix)

def load(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod

mod = load("tasks_review_regress", tw)
lfi = load("lfi_review_regress", lfi_path)

# 4312988824: rollback restores the destination mode after a failed update.
target = root / "tasks" / "mode-keep-4312988824.txt"
target.write_bytes(b"old\n")
os.chmod(target, 0o640)
real_replace = os.replace

def boom_mode(src, dst):
    if str(dst).endswith("mode-fail-4312988824.txt"):
        raise OSError("boom")
    return real_replace(src, dst)

os.replace = boom_mode
try:
    try:
        mod.apply_ops(root, [
            ("update", "tasks/mode-keep-4312988824.txt", None, b"new\n"),
            ("create", "tasks/mode-fail-4312988824.txt", None, b"x"),
        ])
    except mod.Fail as exc:
        if "rolled back" not in exc.message:
            raise SystemExit("4312988824 unexpected rollback error: %s" % exc.message)
    else:
        raise SystemExit("4312988824 mode rollback did not fail closed")
finally:
    os.replace = real_replace
if target.read_bytes() != b"old\n" or stat.S_IMODE(target.stat().st_mode) != 0o640:
    raise SystemExit("4312988824 rollback did not restore destination mode")
if (root / "tasks" / "mode-fail-4312988824.txt").exists():
    raise SystemExit("4312988824 failed create was left behind")
target.unlink()

# 4312988869: a move destination created after planning fails closed.
store = mod.load_store(root)
mod.assert_store_unchanged(store, [("move", "tasks/absent-4312988869.txt", "tasks/index.md", b"x")])
race = root / "tasks" / "race-4312988869.txt"
race.write_text("raced\n", encoding="utf-8")
try:
    try:
        mod.assert_store_unchanged(store, [("move", "tasks/race-4312988869.txt", "tasks/old.txt", b"x")])
    except mod.Fail as exc:
        if "store changed during write" not in exc.message:
            raise SystemExit("4312988869 unexpected error: %s" % exc.message)
    else:
        raise SystemExit("4312988869 move destination was not checked")
finally:
    race.unlink()

# 4312988911: render from the list page and member pointers; do not copy the subtree.
lfi_src = Path(lfi_path).read_text(encoding="utf-8")
for banned in ("copytree", "mkdtemp", "_copy_tree_nofollow", "shutil", "tempfile"):
    if banned in lfi_src:
        raise SystemExit("4312988911 list-folder-index still references %s" % banned)
folder = root / Path(list_rel).parent
attach = folder / "huge.bin"
attach.write_bytes(b"not-a-member")
list_file = root / list_rel
meta, _body = lfi.frontmatter(list_file.read_text(encoding="utf-8"))
rows = []
for uri in lfi.members_of(meta, list_rel):
    ulid = lfi.ulid_of(uri)
    hit = lfi.find_member(root, list_file.parent, ulid)
    if hit is None:
        raise SystemExit("4312988911 member %s not found" % uri)
    path, kind = hit
    member_meta, _b = lfi.frontmatter(path.read_text(encoding="utf-8"))
    rows.append((ulid, kind, path.relative_to(list_file.parent).as_posix(), member_meta.get("title") or path.stem))
expected = lfi.render(list_file, meta, rows)
got, err = lfi.render_list_folder_index(root, list_rel, None)
if err or got != expected:
    raise SystemExit("4312988911 render mismatch: %s" % err)
reads = []
real_rt, real_rb, real_open = Path.read_text, Path.read_bytes, Path.open

def tracked_text(self, *args, **kwargs):
    reads.append(self.name)
    if self.name == "huge.bin":
        raise SystemExit("4312988911 read attachment text")
    return real_rt(self, *args, **kwargs)

def tracked_bytes(self, *args, **kwargs):
    reads.append(self.name)
    if self.name == "huge.bin":
        raise SystemExit("4312988911 read attachment bytes")
    return real_rb(self, *args, **kwargs)

def tracked_open(self, *args, **kwargs):
    reads.append(self.name)
    if self.name == "huge.bin":
        raise SystemExit("4312988911 opened attachment")
    return real_open(self, *args, **kwargs)

Path.read_text, Path.read_bytes, Path.open = tracked_text, tracked_bytes, tracked_open
try:
    got, err = lfi.render_list_folder_index(root, list_rel, None)
    if err or got != expected:
        raise SystemExit("4312988911 hooked render failed: %s" % err)
    if "huge.bin" in reads:
        raise SystemExit("4312988911 render read %s" % reads)
    buf, err_io = io.StringIO(), io.StringIO()
    old, old_e = sys.stdout, sys.stderr
    sys.stdout, sys.stderr = buf, err_io
    try:
        rc = mod.main(["update", "--root", str(root), "--id", mix_id, "--title", "Mixed dry", "--dry-run"])
    finally:
        sys.stdout, sys.stderr = old, old_e
    if rc != 0 or "huge.bin" in reads:
        raise SystemExit("4312988911 dry-run rc=%s reads=%s out=%s err=%s" % (rc, reads, buf.getvalue(), err_io.getvalue()))
    receipt = json.loads(buf.getvalue())
    if receipt.get("dry_run") is not True:
        raise SystemExit("4312988911 dry-run receipt: %s" % receipt)
finally:
    Path.read_text, Path.read_bytes, Path.open = real_rt, real_rb, real_open
attach.unlink()
overlay_ulid = "01J8E3KDT0X8B4D1W2X5Y6Z7F8"
member_ulid = "01J8E3KDT0X8B4D1W2X5Y6Z7F9"
new_rel = "tasks/%s-overlay/%s-overlay.task-list.md" % (overlay_ulid, overlay_ulid)
member_rel = "tasks/%s-overlay/%s-item.md" % (overlay_ulid, member_ulid)
overlay = {
    new_rel: "---\ntype: task-list\ntitle: Overlay list\ntask_id: atlas://ex/tasks/%s\ntasks:\n  - atlas://ex/tasks/%s\n---\n" % (overlay_ulid, member_ulid),
    member_rel: "---\ntype: task\ntitle: Overlay item\ntask_id: atlas://ex/tasks/%s\n---\n" % member_ulid,
}
got, err = lfi.render_list_folder_index(root, new_rel, overlay)
if err or "Overlay item" not in got or (root / "tasks" / ("%s-overlay" % overlay_ulid)).exists():
    raise SystemExit("4312988911 overlay render wrote or failed: %s" % err)

# 4312989062: rollback removes only directories this transaction created, and only when empty.
pre = root / "tasks" / "empty-pre-4312989062"
pre.mkdir()

def boom_dir(src, dst):
    if "created-by-tx" in str(dst):
        raise OSError("boom")
    return real_replace(src, dst)

os.replace = boom_dir
try:
    try:
        mod.apply_ops(root, [
            ("create", "tasks/empty-pre-4312989062/made.md", None, b"x"),
            ("create", "tasks/created-by-tx/page.md", None, b"y"),
        ])
    except mod.Fail as exc:
        if "rolled back" not in exc.message:
            raise SystemExit("4312989062 unexpected rollback error: %s" % exc.message)
    else:
        raise SystemExit("4312989062 created-dir rollback did not fail closed")
finally:
    os.replace = real_replace
if not pre.is_dir() or (pre / "made.md").exists() or (root / "tasks" / "created-by-tx").exists():
    raise SystemExit("4312989062 rollback removed a pre-existing dir or left a created dir")
pre.rmdir()

def boom_retry(src, dst):
    if "rollback-list" in str(dst):
        raise OSError("boom")
    return real_replace(src, dst)

os.replace = boom_retry
buf, err_io = io.StringIO(), io.StringIO()
old, old_e = sys.stdout, sys.stderr
sys.stdout, sys.stderr = buf, err_io
try:
    rc = mod.main(["add", "--root", str(root), "--kind", "task-list", "--title", "Rollback list"])
finally:
    sys.stdout, sys.stderr = old, old_e
    os.replace = real_replace
if rc == 0 or "rolled back" not in buf.getvalue():
    raise SystemExit("4312989062 failed create rc=%s out=%s err=%s" % (rc, buf.getvalue(), err_io.getvalue()))
left = list((root / "tasks").glob("*rollback-list*"))
if left:
    raise SystemExit("4312989062 left %s" % left)
buf, err_io = io.StringIO(), io.StringIO()
sys.stdout, sys.stderr = buf, err_io
try:
    rc = mod.main(["add", "--root", str(root), "--kind", "task-list", "--title", "Rollback list"])
finally:
    sys.stdout, sys.stderr = old, old_e
if rc != 0:
    raise SystemExit("4312989062 retry failed rc=%s out=%s err=%s" % (rc, buf.getvalue(), err_io.getvalue()))
receipt = json.loads(buf.getvalue())
if not receipt.get("ok") or not (root / receipt["path"]).is_file():
    raise SystemExit("4312989062 retry receipt: %s" % receipt)
print("second-review regressions ok")
PY
  pass "4312988824/4312988869/4312988911/4312989062 regressions ($label)"

  rm -f "$FIX.tw.out" "$FIX.tw.err" "$FIX.writer.out" "$FIX.writer.err" \
    "$FIX.shared.out" "$FIX.shared.err" "$FIX.lock.add.out" "$FIX.lock.add.err" \
    "$FIX.lock.holder.out" "$FIX.lock.holder.err" "$FIX.lock.ready" "$FIX.lock.release" \
    "$FIX.race1.out" "$FIX.race1.err" "$FIX.race2.out" "$FIX.race2.err"
  pass "4d tasks.py writer ($label store)"

  python3 "$ATLAS_CLI" compile --root "$FIX" || fail "compile red on $label store (schema_version=$sv)"
  pass "4 atlas compile green on fixture ($label store, schema_version=$sv)"
  rm -rf "$FIX"
}

if [[ -z "$CHECK_ONLY" ]]; then
  run_install_fixture default ""
  # Fail closed: Atlas validates SCHEMA 2.0 stores with jsonschema; never skip silently.
  python3 -c 'import jsonschema' 2>/dev/null \
    || fail "SCHEMA 2.0 smokes need the Python jsonschema package (pip install jsonschema)"
  run_install_fixture "SCHEMA 2.0" "2.0" --schema-version 2.0

  README="$PKG_ROOT/README.md"
  grep -qi 'install' "$README" || fail "README missing install"
  grep -qi 'mount' "$README" || fail "README missing mount"
  pass "6 README install → mount"

  echo "ALL SMOKES GREEN"
fi

rm -f "$HELPERS"
