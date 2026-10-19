#!/usr/bin/env python3
"""Deterministic writer for atlas-tasks add, update, and complete.

Stdlib plus PyYAML only. Never invokes another program. Writes stay inside
--root (no symlink follow). Discovery walks pointers from tasks/index.md
(pin 20). One JSON receipt on stdout.

On an existing page, frontmatter keys the operation did not change are copied
byte-identical (quoting, comments, block/flow style, folded scalars). Only
changed or newly added keys are re-emitted; new keys are appended in the
documented order. Changed scalars use plain style when that round-trips.
"""
from __future__ import annotations

import sys

sys.dont_write_bytecode = True

import argparse
import importlib.util
import json
import os
import re
import secrets
import tempfile
import time
from datetime import date, datetime
from pathlib import Path

try:
    import yaml
except ImportError:
    print("error: PyYAML is required (pip install pyyaml)", file=sys.stderr)
    sys.exit(2)


class Fail(Exception):
    def __init__(self, message: str, code: int = 1):
        super().__init__(message)
        self.message = message
        self.code = code


CROCKFORD = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"
ULID_RE = re.compile(r"^[0-9A-HJKMNP-TV-Z]{26}$")
URI_RE = re.compile(r"^atlas://([^/]+(?:/[^/]+)*)/tasks/([0-9A-HJKMNP-TV-Z]{26})$")
DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")
ALLOWED_STATUS = {"open", "in_progress", "done", "cancelled"}
FORBIDDEN = {
    "todo_id",
    "todo_status",
    "depends_on",
    "display_slug",
    "members",
    "blocked_by",
    "assignee",
}
TASK_KEYS = [
    "type",
    "title",
    "created",
    "task_id",
    "task_status",
    "body_path",
    "related_node",
    "assignees",
    "parent",
    "sub_tasks",
    "task_list",
    "relates_to",
]
LIST_KEYS = ["type", "title", "created", "task_id", "task_list", "tasks"]
DOC_KEYS = ["type", "title", "created"]
TASK_REQUIRED = [
    "type",
    "title",
    "created",
    "task_id",
    "task_status",
    "body_path",
    "related_node",
    "assignees",
    "parent",
    "sub_tasks",
    "relates_to",
]
POINTER_BODY = (
    "\n## Content\n\n"
    "Pointer only. Full prose lives in the colocated body page; this task page "
    "stays a short pointer and is not the body.\n"
)
LIST_BODY = (
    "\n## Members\n\n"
    "This task list starts empty. Membership is the frontmatter tasks pointers "
    "plus a body mention of each member. Do not copy nested members into a pointing list.\n"
)

_LFI = None


def lfi():
    global _LFI
    if _LFI is None:
        path = Path(__file__).resolve().parent / "list-folder-index.py"
        spec = importlib.util.spec_from_file_location("atlas_tasks_list_folder_index", path)
        if spec is None or spec.loader is None:
            raise Fail("cannot load list-folder-index.py")
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
        _LFI = mod
    return _LFI


def file_safe_name(title: str, max_len: int = 48) -> str:
    # pin 16; same rule as scripts/smoke-check.sh file_safe_name
    s = re.sub(r"[^a-z0-9]+", "-", (title or "").lower()).strip("-")
    if not s:
        s = "item"
    return s[:max_len].strip("-") or "item"


def mint_ulid() -> str:
    # pin 11: 48-bit ms timestamp + 80 random bits, Crockford Base32
    ts = int(time.time() * 1000) & ((1 << 48) - 1)
    rand = int.from_bytes(secrets.token_bytes(10), "big") & ((1 << 80) - 1)
    return _encode(ts, 10) + _encode(rand, 16)


def _encode(value: int, length: int) -> str:
    chars = []
    for _ in range(length):
        chars.append(CROCKFORD[value & 31])
        value >>= 5
    return "".join(reversed(chars))


def parse_uri(value: str):
    if not isinstance(value, str):
        return None
    m = URI_RE.match(value.strip())
    if not m:
        return None
    return m.group(1), m.group(2)


def blank(value) -> bool:
    return value is None or value == "" or value == "null"


def norm_rel(raw: str) -> str:
    raw = (raw or "").strip().replace("\\", "/")
    if not raw or raw.startswith("/") or raw.startswith("~"):
        raise Fail("path must be store-relative")
    parts = Path(raw).parts
    if any(part in ("", "..") for part in parts):
        raise Fail("path escapes root")
    return Path(raw).as_posix()


def contained(root: Path, path: Path) -> bool:
    if path.is_symlink():
        return False
    try:
        path.resolve().relative_to(root.resolve())
    except (ValueError, OSError):
        return False
    return True


def safe_path(root: Path, rel: str) -> Path:
    rel = norm_rel(rel)
    dest = root / rel
    cur = root
    if cur.is_symlink() or not contained(root, cur):
        raise Fail("refuse symlink or path outside root")
    for part in Path(rel).parts:
        cur = cur / part
        if cur.is_symlink():
            raise Fail("refuse symlink or path outside root")
        if cur.exists() and not contained(root, cur):
            raise Fail("refuse symlink or path outside root")
    return dest


def exists_inside(root: Path, rel: str) -> bool:
    try:
        path = safe_path(root, rel)
    except Fail:
        return False
    return path.exists() and not path.is_symlink()


def read_atlas_id(root: Path) -> str:
    for name in ("CONTRACT.json", "SCHEMA.json"):
        path = root / name
        if not path.is_file() or path.is_symlink() or not contained(root, path):
            continue
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            continue
        if isinstance(data, dict):
            aid = str(data.get("atlas_id") or "").strip()
            if aid:
                return aid
    raise Fail("incomplete: missing Atlas id")


def load_overlay_required(root: Path) -> list[str]:
    path = root / "schema.d" / "atlas-tasks.json"
    if not path.is_file() or path.is_symlink() or not contained(root, path):
        raise Fail("schema.d/atlas-tasks.json missing; run mount-overlay")
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as e:
        raise Fail("schema.d/atlas-tasks.json is not readable; run mount-overlay") from e
    if not isinstance(data, dict) or data.get("contribution_id") != "atlas-tasks":
        raise Fail("schema.d/atlas-tasks.json contribution_id is not atlas-tasks; run mount-overlay")
    block = ((data.get("templates") or {}).get("by_type") or {}).get("task-list") or {}
    required = ((block.get("frontmatter") or {}).get("required")) or []
    if not isinstance(required, list) or not required:
        raise Fail("installed overlay is missing task-list required frontmatter; run mount-overlay")
    return [str(item) for item in required]


def validate_date(value: str) -> str:
    if not DATE_RE.match(value or ""):
        raise Fail("created must be YYYY-MM-DD")
    try:
        datetime.strptime(value, "%Y-%m-%d")
    except ValueError as e:
        raise Fail("created must be YYYY-MM-DD") from e
    return value


def one_line(value: str, label: str) -> str:
    value = (value or "").strip()
    if not value or "\n" in value or "\r" in value:
        raise Fail(f"{label} must be a single line")
    return value


# YAML 1.1 plain scalars must not start with an indicator, and these tokens are
# bool / null even when a given PyYAML build leaves `y`/`n` as strings.
_PLAIN_BAD_START = set("-?:,[]{}#&*!|>'\"%@`")
_YAML_BOOL = {
    "y", "Y", "yes", "Yes", "YES",
    "n", "N", "no", "No", "NO",
    "true", "True", "TRUE",
    "false", "False", "FALSE",
    "on", "On", "ON",
    "off", "Off", "OFF",
}
_YAML_NULL = {"null", "Null", "NULL", "~"}
_NUMBERISH = re.compile(
    r"^(?:"
    r"[-+]?(?:0|[1-9][0-9_]*)(?:\.[0-9_]*)?(?:[eE][-+]?[0-9]+)?|"
    r"[-+]?\.[0-9_]+(?:[eE][-+]?[0-9]+)?|"
    r"[-+]?\.(?:inf|Inf|INF|nan|NaN|NAN)|"
    r"0x[0-9A-Fa-f_]+|"
    r"0o[0-7_]+|"
    r"0b[01_]+|"
    r"\d[\d_]*:\d[\d_]*(?::\d[\d_]*)?"
    r")$"
)
_DATEISH = re.compile(r"^\d{4}-\d{1,2}-\d{1,2}(?:[T t].*)?$")
_FM_RE = re.compile(r"^---\n(.*?)\n---\n?", re.S)


def quote_scalar(value: str) -> str:
    escaped = (
        value.replace("\\", "\\\\")
        .replace('"', '\\"')
        .replace("\n", "\\n")
        .replace("\r", "\\r")
        .replace("\t", "\\t")
    )
    return f'"{escaped}"'


def scalar_plain_safe(value: str) -> bool:
    """True when `value` can be a plain YAML scalar and still load as the same str."""
    if not value or value != value.strip():
        return False
    if any(ch in value for ch in "\n\r\t"):
        return False
    if value[0] in _PLAIN_BAD_START:
        return False
    if ": " in value or " #" in value or value.endswith(":"):
        return False
    if value in _YAML_BOOL or value in _YAML_NULL or value in {"---", "...", "<<"}:
        return False
    if _NUMBERISH.match(value) or _DATEISH.match(value):
        return False
    try:
        loaded = yaml.safe_load(value)
    except yaml.YAMLError:
        return False
    return isinstance(loaded, str) and loaded == value


def emit_scalar(value, plain: bool = False) -> str:
    if value is None:
        return "null"
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, int) and not isinstance(value, bool):
        return str(value)
    if isinstance(value, str):
        if plain and scalar_plain_safe(value):
            return value
        return quote_scalar(value)
    raise Fail(f"unsupported frontmatter value {type(value).__name__}")


def emit_block(key: str, value, indent: int, plain: bool = False) -> str:
    pad = "  " * indent
    if isinstance(value, list):
        if not value:
            return f"{pad}{key}: []"
        lines = [f"{pad}{key}:"]
        for item in value:
            if isinstance(item, dict):
                keys = list(item.keys())
                if not keys:
                    lines.append(f"{pad}  - {{}}")
                    continue
                first = keys[0]
                lines.append(f"{pad}  - {first}: {emit_scalar(item[first], plain)}")
                for extra in keys[1:]:
                    lines.append(f"{pad}    {extra}: {emit_scalar(item[extra], plain)}")
            elif isinstance(item, list):
                raise Fail("nested lists are not supported in frontmatter")
            else:
                lines.append(f"{pad}  - {emit_scalar(item, plain)}")
        return "\n".join(lines)
    if isinstance(value, dict):
        lines = [f"{pad}{key}:"]
        for child_key, child_val in value.items():
            lines.append(emit_block(str(child_key), child_val, indent + 1, plain))
        return "\n".join(lines)
    return f"{pad}{key}: {emit_scalar(value, plain)}"


def emit_frontmatter(meta: dict, key_order: list[str]) -> str:
    keys = [key for key in key_order if key in meta]
    for key in meta:
        if key not in keys:
            keys.append(key)
    lines = ["---"]
    for key in keys:
        lines.append(emit_block(key, meta[key], 0))
    lines.append("---")
    return "\n".join(lines) + "\n"


def canon(value):
    if isinstance(value, dict):
        return {str(k): canon(v) for k, v in value.items()}
    if isinstance(value, list):
        return [canon(v) for v in value]
    return value


def split_page(text: str) -> tuple[dict, str]:
    m = _FM_RE.match(text)
    if not m:
        raise Fail("missing frontmatter")
    try:
        meta = yaml.safe_load(m.group(1)) or {}
    except yaml.YAMLError as e:
        raise Fail(f"invalid YAML frontmatter: {e}") from e
    if not isinstance(meta, dict):
        raise Fail("frontmatter is not a mapping")
    return meta, text[m.end():]


def key_spans(inner: str) -> list[tuple[str, int, int]] | None:
    """Byte spans of top-level keys inside frontmatter source, or None if unusable.

    Each span runs from the key token through the value token (PyYAML marks).
    Comments and blank lines between keys sit outside the spans, so copying the
    original text and replacing only a dirty span leaves them byte-identical.
    """
    loader = yaml.SafeLoader(inner)
    try:
        try:
            node = loader.get_single_node()
        except yaml.YAMLError:
            return None
    finally:
        loader.dispose()
    if node is None:
        return []
    if not isinstance(node, yaml.MappingNode):
        return None
    spans: list[tuple[str, int, int]] = []
    last_end = 0
    for key_node, value_node in node.value:
        if not isinstance(key_node, yaml.ScalarNode):
            return None
        start = key_node.start_mark.index
        end = value_node.end_mark.index
        if start < last_end or end < start or end > len(inner):
            return None
        spans.append((str(key_node.value), start, end))
        last_end = end
    return spans


def frontmatter_source(text: str) -> tuple[str, str, list[tuple[str, int, int]]] | None:
    """Return (inner, closing fence, key spans) for an existing page, or None."""
    m = _FM_RE.match(text)
    if not m:
        return None
    inner = m.group(1)
    close = text[m.end(1) : m.end()]
    spans = key_spans(inner)
    if spans is None:
        return None
    return inner, close, spans


def splice_keys(
    inner: str,
    spans: list[tuple[str, int, int]],
    replacements: dict[str, str | None],
    appended: list[str],
) -> str:
    """Replace or drop dirty key spans; leave every other byte of `inner` alone."""
    by_key: dict[str, list[tuple[int, int]]] = {}
    for key, start, end in spans:
        by_key.setdefault(key, []).append((start, end))
    edits: list[tuple[int, int, str | None]] = []
    for key, repl in replacements.items():
        occ = by_key.get(key) or []
        if not occ:
            continue
        if repl is None:
            for start, end in occ:
                edits.append((start, end, None))
        else:
            for start, end in occ[:-1]:
                edits.append((start, end, None))
            edits.append((occ[-1][0], occ[-1][1], repl))
    text = inner
    for start, end, repl in sorted(edits, key=lambda item: item[0], reverse=True):
        if end > start and text[end - 1] == "\n":
            end -= 1
        if repl is None:
            if end < len(text) and text[end] == "\n":
                end += 1
            elif start > 0 and text[start - 1] == "\n":
                start -= 1
            text = text[:start] + text[end:]
        else:
            text = text[:start] + repl + text[end:]
    if appended:
        if text and not text.endswith("\n"):
            text += "\n"
        text += "\n".join(appended)
    return text


class Page:
    def __init__(self, rel: str, meta: dict, body: str, original: str | None, kind: str):
        self.rel = rel
        self.original_rel = rel if original is not None else None
        self.meta = meta
        self.body = body
        self.original = original
        self.kind = kind
        self.key_order = list(meta.keys())
        self.meta_dirty = original is None
        self.body_dirty = False
        self.dirty_keys: set[str] = set()
        self.deleted_keys: set[str] = set()
        self.added_keys: list[str] = []
        self.fm_inner: str | None = None
        self.fm_close = "\n---\n"
        self.key_spans: list[tuple[str, int, int]] | None = None
        if original is not None:
            source = frontmatter_source(original)
            if source is not None:
                self.fm_inner, self.fm_close, self.key_spans = source

    @property
    def uri(self) -> str:
        return str(self.meta.get("task_id") or "")

    @property
    def ulid(self) -> str:
        parsed = parse_uri(self.uri)
        return parsed[1] if parsed else ""

    def set_meta(self, key: str, value) -> None:
        self.meta[key] = value
        self._place_key(key)
        self.meta_dirty = True
        self.dirty_keys.add(key)
        self.deleted_keys.discard(key)
        if self.key_spans is not None and not any(k == key for k, _, _ in self.key_spans):
            if key not in self.added_keys:
                self.added_keys.append(key)

    def del_meta(self, key: str) -> None:
        if key in self.meta:
            del self.meta[key]
            self.meta_dirty = True
            self.dirty_keys.add(key)
            self.deleted_keys.add(key)
            if key in self.added_keys:
                self.added_keys.remove(key)

    def set_body(self, body: str) -> None:
        if body != self.body:
            self.body = body
            self.body_dirty = True

    def _place_key(self, key: str) -> None:
        if key in self.key_order:
            return
        canonical = TASK_KEYS if self.kind == "task" else LIST_KEYS if self.kind == "task-list" else DOC_KEYS
        if key in canonical:
            idx = canonical.index(key)
            insert_at = len(self.key_order)
            for i, existing in enumerate(self.key_order):
                if existing in canonical and canonical.index(existing) > idx:
                    insert_at = i
                    break
            self.key_order.insert(insert_at, key)
        else:
            self.key_order.append(key)

    def _appended_keys(self) -> list[str]:
        present = {key for key, _, _ in self.key_spans or []}
        canonical = TASK_KEYS if self.kind == "task" else LIST_KEYS if self.kind == "task-list" else DOC_KEYS
        new = [key for key in self.meta if key not in present]

        def rank(key: str) -> tuple[int, int]:
            if key in canonical:
                return (0, canonical.index(key))
            try:
                return (1, self.added_keys.index(key))
            except ValueError:
                return (1, 10**9)

        new.sort(key=rank)
        return new

    def _render_preserved(self) -> str:
        spans = self.key_spans or []
        present = {key for key, _, _ in spans}
        replacements: dict[str, str | None] = {}
        for key in self.dirty_keys:
            if key not in present:
                continue
            if key in self.deleted_keys or key not in self.meta:
                replacements[key] = None
            else:
                replacements[key] = emit_block(key, self.meta[key], 0, plain=True)
        appended = [emit_block(key, self.meta[key], 0, plain=True) for key in self._appended_keys()]
        inner = splice_keys(self.fm_inner or "", spans, replacements, appended)
        return "---\n" + inner + self.fm_close

    def _check_round_trip(self, rendered: str) -> None:
        m = _FM_RE.match(rendered)
        if not m:
            raise Fail(f"{self.rel}: emitted frontmatter is not YAML")
        try:
            parsed = yaml.safe_load(m.group(1))
        except yaml.YAMLError as e:
            raise Fail(f"{self.rel}: emitted frontmatter is not YAML") from e
        if canon(parsed) != canon(self.meta):
            raise Fail(f"{self.rel}: frontmatter did not round-trip")

    def output_text(self) -> str:
        if self.original is not None and not self.meta_dirty:
            if not self.body_dirty and self.rel == self.original_rel:
                return self.original
            m = _FM_RE.match(self.original)
            if not m:
                raise Fail(f"{self.rel}: missing frontmatter")
            return self.original[: m.end()] + self.body
        if self.original is not None and self.fm_inner is not None and self.key_spans is not None:
            rendered = self._render_preserved()
        else:
            # New pages keep the add.md sample style (quoted scalars are fine).
            rendered = emit_frontmatter(self.meta, self.key_order)
        self._check_round_trip(rendered)
        return rendered + self.body

    def output_bytes(self) -> bytes:
        return self.output_text().encode("utf-8")


class Store:
    def __init__(self, root: Path, atlas_id: str):
        self.root = root
        self.atlas_id = atlas_id
        self.pages: dict[str, Page] = {}
        self.by_uri: dict[str, Page] = {}
        self.by_ulid: dict[str, Page] = {}
        self.reached_folders: set[str] = set()
        self.extra_moves: list[tuple[str, str, str]] = []
        self.relocated_index: dict[str, tuple[str, str | None]] = {}
        self.root_page: Page | None = None

    def add_page(self, page: Page, is_root: bool = False) -> None:
        if page.ulid and page.ulid in self.by_ulid and self.by_ulid[page.ulid] is not page:
            raise Fail("ULID collision")
        self.pages[page.rel] = page
        if page.uri:
            self.by_uri[page.uri] = page
        if page.ulid:
            self.by_ulid[page.ulid] = page
        if is_root:
            self.root_page = page

    def move_page(self, page: Page, new_rel: str) -> None:
        new_rel = norm_rel(new_rel)
        if new_rel == page.rel:
            return
        if new_rel in self.pages:
            raise Fail("target path already exists")
        dest = self.root / new_rel
        if dest.exists() and not dest.is_symlink():
            raise Fail("target path already exists")
        old = page.rel
        self.pages.pop(old, None)
        page.rel = new_rel
        self.pages[new_rel] = page

    def resolve(self, ref: str) -> Page:
        ref = (ref or "").strip()
        if not ref:
            raise Fail("unknown id")
        parsed = parse_uri(ref)
        if parsed:
            if parsed[0] != self.atlas_id:
                raise Fail("unknown id")
            page = self.by_ulid.get(parsed[1])
            if page is None:
                raise Fail("unknown id")
            return page
        if ULID_RE.match(ref):
            page = self.by_ulid.get(ref)
            if page is None:
                raise Fail("unknown id")
            return page
        try:
            rel = norm_rel(ref)
        except Fail:
            raise Fail("unknown id") from None
        if rel in self.pages:
            return self.pages[rel]
        name = Path(rel).name
        m = re.match(r"^([0-9A-HJKMNP-TV-Z]{26})", name)
        folder = str(Path(rel).parent).replace("\\", "/")
        if folder == ".":
            folder = "tasks"
        # pin 20: ULID-prefix match only inside a folder already reached
        if m and folder in self.reached_folders:
            hit = lfi().find_member(self.root, self.root / folder, m.group(1))
            if hit is not None:
                hit_rel = hit[0].relative_to(self.root).as_posix()
                if hit_rel in self.pages:
                    return self.pages[hit_rel]
            page = self.by_ulid.get(m.group(1))
            if page is not None and Path(page.rel).parent.as_posix() == folder:
                return page
        raise Fail("unknown id")

    def overlay(self) -> dict[str, str | None]:
        ov: dict[str, str | None] = {}
        for page in self.pages.values():
            moved = page.original_rel is not None and page.original_rel != page.rel
            if page.original is None or page.meta_dirty or page.body_dirty or moved:
                ov[page.rel] = page.output_text()
            if moved and page.original_rel:
                ov[page.original_rel] = None
        for old, new, text in self.extra_moves:
            ov[new] = text
            ov[old] = None
        return ov


def read_page(root: Path, rel: str) -> Page:
    path = safe_path(root, rel)
    if not path.is_file():
        raise Fail(f"missing page {rel}")
    text = path.read_text(encoding="utf-8")
    meta, body = split_page(text)
    kind = str(meta.get("type") or "")
    if kind not in ("task", "task-list", "document"):
        kind = "other"
    return Page(rel, meta, body, text, kind if kind != "other" else str(meta.get("type") or "other"))


def load_store(root: Path) -> Store:
    # pin 20: walk pointers from the root only; no store-wide scan
    if not root.is_dir() or root.is_symlink():
        raise Fail("incomplete: missing Atlas id")
    atlas_id = read_atlas_id(root)
    tasks = root / "tasks"
    if not tasks.is_dir() or tasks.is_symlink() or not contained(root, tasks):
        raise Fail("tasks/index.md missing or not type: task-list; run mount-overlay or migrate")
    index = tasks / "index.md"
    if not index.is_file() or index.is_symlink():
        raise Fail("tasks/index.md missing or not type: task-list; run mount-overlay or migrate")
    store = Store(root, atlas_id)
    root_page = read_page(root, "tasks/index.md")
    if root_page.meta.get("type") != "task-list":
        raise Fail("tasks/index.md missing or not type: task-list; run mount-overlay or migrate")
    root_page.kind = "task-list"
    store.add_page(root_page, is_root=True)
    queue = [root_page]
    seen_lists: set[str] = set()
    while queue:
        current = queue.pop(0)
        folder = Path(current.rel).parent.as_posix()
        store.reached_folders.add(folder)
        try:
            uris = lfi().members_of(current.meta, current.rel)
        except lfi().FrontmatterError as e:
            raise Fail(str(e)) from e
        for uri in uris:
            ulid = lfi().ulid_of(uri)
            if not ulid:
                continue
            hit = lfi().find_member(root, root / folder, ulid)
            if hit is None:
                continue
            path, kind = hit
            rel = path.relative_to(root).as_posix()
            page = store.pages.get(rel)
            if page is None:
                page = read_page(root, rel)
                if kind == "list":
                    page.kind = "task-list"
                elif kind == "task":
                    page.kind = "task"
                store.add_page(page)
            if kind == "list" and ulid not in seen_lists:
                seen_lists.add(ulid)
                queue.append(page)
    return store


def accept_ulid(store: Store, supplied: str | None) -> str:
    if supplied:
        parsed = parse_uri(supplied)
        if not parsed or parsed[0] != store.atlas_id or not ULID_RE.match(parsed[1]):
            raise Fail("attempted duplicate: malformed or other-Atlas task_id")
        if parsed[1] in store.by_ulid:
            raise Fail("attempted duplicate: task_id already reachable")
        return parsed[1]
    ulid = mint_ulid()
    if not ULID_RE.match(ulid):
        raise Fail("minted ULID was malformed")
    if ulid in store.by_ulid:
        ulid = mint_ulid()
        if ulid in store.by_ulid or not ULID_RE.match(ulid):
            raise Fail("minted ULID collided after remint")
    return ulid


def append_mention(body: str, title: str, uri: str, rel: str) -> str:
    if uri in body:
        return body
    if body and not body.endswith("\n"):
        body += "\n"
    if body and not body.endswith("\n\n"):
        body += "\n"
    return body + f"- {title} — {uri} — {rel}\n"


def remove_mention_lines(body: str, uri: str) -> str:
    return "".join(line for line in body.splitlines(keepends=True) if uri not in line)


def rewrite_paths(store: Store, pairs: list[tuple[str, str]]) -> None:
    ordered = sorted((old, new) for old, new in pairs if old and old != new)
    ordered.sort(key=lambda item: len(item[0]), reverse=True)
    if not ordered:
        return
    for page in list(store.pages.values()):
        body = page.body
        for old, new in ordered:
            body = body.replace(old, new)
        page.set_body(body)


def append_unique(page: Page, key: str, uri: str) -> None:
    values = list(page.meta.get(key) or [])
    if uri not in values:
        values.append(uri)
        page.set_meta(key, values)


def remove_value(page: Page, key: str, uri: str) -> None:
    values = [item for item in (page.meta.get(key) or []) if item != uri]
    page.set_meta(key, values)


def add_member(owner: Page, title: str, uri: str, rel: str) -> None:
    tasks = list(owner.meta.get("tasks") or [])
    if uri not in tasks:
        tasks.append(uri)
        owner.set_meta("tasks", tasks)
    owner.set_body(append_mention(owner.body, title, uri, rel))


def remove_member(owner: Page, uri: str) -> None:
    tasks = [item for item in (owner.meta.get("tasks") or []) if item != uri]
    owner.set_meta("tasks", tasks)
    owner.set_body(remove_mention_lines(owner.body, uri))


def append_edge(page: Page, uri: str, kind: str) -> None:
    edges = list(page.meta.get("relates_to") or [])
    for edge in edges:
        if isinstance(edge, dict) and edge.get("kind") == kind and edge.get("path") == uri:
            return
    edges.append({"path": uri, "kind": kind})
    page.set_meta("relates_to", edges)


def edge_uri(store: Store, path) -> str | None:
    if not isinstance(path, str):
        return None
    parsed = parse_uri(path)
    if parsed and parsed[0] == store.atlas_id:
        page = store.by_ulid.get(parsed[1])
        return page.uri if page else path
    if parsed:
        return path
    page = store.pages.get(path) or store.by_ulid.get(path)
    if page:
        return page.uri
    return None


def remove_edge(store: Store, page: Page, uri: str, kind: str) -> bool:
    kept = []
    removed = False
    for edge in page.meta.get("relates_to") or []:
        if isinstance(edge, dict) and edge.get("kind") == kind and edge_uri(store, edge.get("path")) == uri:
            removed = True
            continue
        kept.append(edge)
    if removed:
        page.set_meta("relates_to", kept)
    return removed


def would_parent_cycle(store: Store, child_uri: str, parent_uri: str) -> bool:
    # pin 7
    if child_uri == parent_uri:
        return True
    seen = set()
    cur = parent_uri
    while cur and cur not in (None, "", "null"):
        if cur == child_uri or cur in seen:
            return True
        seen.add(cur)
        page = store.by_uri.get(cur)
        if page is None:
            return False
        cur = page.meta.get("parent")
    return False


def would_dep_cycle(store: Store, waiter_uri: str, blocker_uri: str) -> bool:
    # pin 8
    if waiter_uri == blocker_uri:
        return True
    seen = set()
    stack = [blocker_uri]
    while stack:
        cur = stack.pop()
        if cur == waiter_uri:
            return True
        if cur in seen:
            continue
        seen.add(cur)
        page = store.by_uri.get(cur)
        if page is None:
            continue
        for edge in page.meta.get("relates_to") or []:
            if not isinstance(edge, dict) or edge.get("kind") != "dependency":
                continue
            target = edge_uri(store, edge.get("path"))
            if target and parse_uri(target) and parse_uri(target)[0] == store.atlas_id:
                stack.append(target)
    return False


def resolve_parent(store: Store, ref: str) -> Page:
    parsed = parse_uri(ref or "")
    if not parsed:
        raise Fail("parent must be a same-Atlas atlas:// URI")
    if parsed[0] != store.atlas_id:
        raise Fail("cross-Atlas parent")
    page = store.by_ulid.get(parsed[1])
    if page is None or page.kind != "task":
        raise Fail("parent is not a reachable type: task")
    return page


def resolve_list_arg(store: Store, ref: str) -> Page:
    parsed = parse_uri(ref or "")
    if parsed:
        if parsed[0] != store.atlas_id:
            raise Fail("task_list is not in this Atlas")
        page = store.by_ulid.get(parsed[1])
        if page is None:
            raise Fail("unknown task_list")
    else:
        page = store.resolve(ref)
    if page.kind != "task-list":
        raise Fail("task_list is not a task list")
    return page


def resolve_dependency(store: Store, ref: str) -> dict:
    parsed = parse_uri(ref or "")
    if parsed and parsed[0] != store.atlas_id:
        return {"uri": ref.strip(), "cross": True, "page": None}
    try:
        page = store.resolve(ref)
    except Fail:
        raise Fail("unknown dependency target") from None
    if page.kind != "task":
        raise Fail("dependency target is not a type: task")
    return {"uri": page.uri, "cross": False, "page": page}


def owner_of(store: Store, page: Page) -> Page:
    tl = page.meta.get("task_list")
    if blank(tl) or "task_list" not in page.meta:
        return store.root_page
    owner = store.by_uri.get(tl)
    if owner is None or owner.kind != "task-list":
        raise Fail("task_list does not resolve")
    return owner


def new_page(rel: str, meta: dict, body: str, kind: str) -> Page:
    page = Page(rel, meta, body, None, kind)
    page.key_order = [key for key in (TASK_KEYS if kind == "task" else LIST_KEYS if kind == "task-list" else DOC_KEYS) if key in meta]
    return page


def body_rel_for(root: Path, related: str, ulid: str) -> str:
    node = safe_path(root, related)
    if not node.exists() or node.is_symlink():
        raise Fail("related_node does not exist")
    folder = node.parent if node.is_file() else node
    if folder.is_symlink() or not contained(root, folder):
        raise Fail("related_node does not exist")
    rel = folder.relative_to(root).as_posix()
    name = f"task-{ulid[-8:].lower()}.md"
    return f"{rel}/{name}" if rel != "." else name


def mark(affected: list[str], folder: str) -> None:
    if folder and folder != "tasks" and folder not in affected:
        affected.append(folder)


def place_task(store: Store, ulid: str, title: str, list_page: Page | None) -> tuple[str, Page, str | None]:
    name = file_safe_name(title)
    if list_page is None:
        rel = f"tasks/{ulid}-{name}.md"
        return rel, store.root_page, None
    folder = Path(list_page.rel).parent.as_posix()
    return f"{folder}/{ulid}-{name}.md", list_page, list_page.uri


def ensure_absent(store: Store, rel: str) -> None:
    if rel in store.pages or (store.root / rel).exists():
        raise Fail("target path already exists")


def add_task(store: Store, args, affected: list[str]) -> Page:
    if args.status and args.status not in ALLOWED_STATUS:
        raise Fail("task_status must be open|in_progress|done|cancelled")
    if not args.related_node:
        raise Fail("related_node is required for a task")
    related = norm_rel(args.related_node)
    if not exists_inside(store.root, related):
        raise Fail("related_node does not exist")
    title = one_line(args.title, "title")
    created = validate_date(args.created or date.today().isoformat())
    status = args.status or "open"
    assignees = [one_line(item, "assignee") for item in (args.assignee or [])]
    list_page = None
    if args.task_list:
        list_page = resolve_list_arg(store, args.task_list)
        if list_page.uri == store.root_page.uri:
            raise Fail("task_list set to the root task-list URI")
    parent = resolve_parent(store, args.parent) if args.parent else None
    blockers = [resolve_dependency(store, ref) for ref in (args.depends_on or [])]
    ulid = accept_ulid(store, args.task_id)
    task_id = f"atlas://{store.atlas_id}/tasks/{ulid}"
    if parent and would_parent_cycle(store, task_id, parent.uri):
        raise Fail("hierarchy cycle")
    for blocker in blockers:
        if not blocker["cross"] and would_dep_cycle(store, task_id, blocker["uri"]):
            raise Fail("dependency cycle")
    rel, owner, task_list = place_task(store, ulid, title, list_page)
    ensure_absent(store, rel)
    if args.body_path:
        body_path = norm_rel(args.body_path)
        if not exists_inside(store.root, body_path) or not (store.root / body_path).is_file():
            raise Fail("body_path does not exist")
    else:
        if args.body is None or not str(args.body).strip():
            raise Fail("empty body; pass --body or --body-path")
        body_path = body_rel_for(store.root, related, ulid)
        ensure_absent(store, body_path)
        doc = new_page(
            body_path,
            {
                "type": "document",
                "title": f"Task body — {title}",
                "created": created,
            },
            "\n" + str(args.body).strip() + "\n",
            "document",
        )
        store.add_page(doc)
    meta = {
        "type": "task",
        "title": title,
        "created": created,
        "task_id": task_id,
        "task_status": status,
        "body_path": body_path,
        "related_node": related,
        "assignees": assignees,
        "parent": parent.uri if parent else None,
        "sub_tasks": [],
        "relates_to": [],
    }
    if task_list:
        meta["task_list"] = task_list
    page = new_page(rel, meta, POINTER_BODY, "task")
    store.add_page(page)
    add_member(owner, title, task_id, rel)
    if parent:
        append_unique(parent, "sub_tasks", task_id)
    for blocker in blockers:
        append_edge(page, blocker["uri"], "dependency")
        if not blocker["cross"]:
            append_edge(blocker["page"], task_id, "blocks")
    if list_page is not None:
        mark(affected, Path(list_page.rel).parent.as_posix())
    return page


def add_list(store: Store, args, affected: list[str]) -> Page:
    if any(
        [
            args.status,
            args.related_node,
            args.body,
            args.body_path,
            args.assignee,
            args.parent,
            args.depends_on,
        ]
    ):
        raise Fail("task-only flags are not valid for a task list")
    title = one_line(args.title, "title")
    created = validate_date(args.created or date.today().isoformat())
    parent = store.root_page if not args.task_list else resolve_list_arg(store, args.task_list)
    ulid = accept_ulid(store, args.task_id)
    task_id = f"atlas://{store.atlas_id}/tasks/{ulid}"
    name = file_safe_name(title)
    parent_folder = Path(parent.rel).parent.as_posix()
    folder = f"{parent_folder}/{ulid}-{name}"
    rel = f"{folder}/{ulid}-{name}.task-list.md"
    ensure_absent(store, rel)
    if (store.root / folder).exists():
        raise Fail("target path already exists")
    page = new_page(
        rel,
        {
            "type": "task-list",
            "title": title,
            "created": created,
            "task_id": task_id,
            "task_list": parent.uri,
            "tasks": [],
        },
        LIST_BODY,
        "task-list",
    )
    store.add_page(page)
    store.reached_folders.add(folder)
    add_member(parent, title, task_id, rel)
    mark(affected, folder)
    if parent is not store.root_page:
        mark(affected, parent_folder)
    return page


def rename_title(store: Store, page: Page, title: str, affected: list[str]) -> None:
    title = one_line(title, "title")
    old_rel = page.rel
    page.set_meta("title", title)
    if page is store.root_page:
        return  # pin 16/21: root path stays tasks/index.md
    ulid = page.ulid
    name = file_safe_name(title)
    if page.kind == "task":
        folder = Path(old_rel).parent.as_posix()
        new_rel = f"{folder}/{ulid}-{name}.md"
        if new_rel != old_rel:
            store.move_page(page, new_rel)
            rewrite_paths(store, [(old_rel, new_rel), (Path(old_rel).name, Path(new_rel).name)])
        mark(affected, folder)
        return
    old_folder = Path(old_rel).parent.as_posix()
    parent_folder = Path(old_folder).parent.as_posix()
    new_folder = f"{parent_folder}/{ulid}-{name}"
    new_rel = f"{new_folder}/{ulid}-{name}.task-list.md"
    move_list_folder(store, page, old_folder, new_folder, new_rel)
    rewrite_paths(
        store,
        [
            (old_rel, new_rel),
            (old_folder + "/", new_folder + "/"),
            (old_folder, new_folder),
        ],
    )
    mark(affected, new_folder)
    if parent_folder != "tasks":
        mark(affected, parent_folder)


def move_list_folder(store: Store, list_page: Page, old_folder: str, new_folder: str, new_rel: str) -> None:
    files = []
    base = store.root / old_folder
    if base.is_dir() and not base.is_symlink():
        for path in base.rglob("*"):
            if path.is_symlink() or not path.is_file() or not contained(store.root, path):
                continue
            files.append(path.relative_to(store.root).as_posix())
    old_index = f"{old_folder}/index.md"
    index_text = None
    if old_index in files:
        index_text = (store.root / old_index).read_text(encoding="utf-8")
        store.relocated_index[new_folder] = (old_index, index_text)
    moved = set()
    for rel in files:
        if rel == old_index:
            continue
        suffix = rel[len(old_folder) + 1 :]
        dest = new_rel if rel == list_page.rel else f"{new_folder}/{suffix}"
        if rel in store.pages:
            store.move_page(store.pages[rel], dest)
            moved.add(rel)
        else:
            text = (store.root / rel).read_text(encoding="utf-8")
            store.extra_moves.append((rel, dest, text))
    if list_page.rel != new_rel:
        store.move_page(list_page, new_rel)
    store.reached_folders.add(new_folder)


def set_membership(store: Store, task: Page, list_page: Page | None, affected: list[str]) -> None:
    if task.kind != "task":
        raise Fail(
            "unsupported: reparenting or clearing task_list on a nested task-list is not supported in v0.8.0; use the manual update path",
            code=3,
        )
    if list_page is not None and list_page.uri == store.root_page.uri:
        raise Fail("task_list set to the root task-list URI")
    current = task.meta.get("task_list")
    current_blank = blank(current) or "task_list" not in task.meta
    if list_page is None and current_blank and Path(task.rel).parent.as_posix() == "tasks":
        return
    if list_page is not None and current == list_page.uri:
        return
    old_owner = owner_of(store, task)
    old_folder = Path(old_owner.rel).parent.as_posix() if old_owner is not store.root_page else "tasks"
    remove_member(old_owner, task.uri)
    old_rel = task.rel
    filename = Path(task.rel).name
    if list_page is None:
        new_rel = f"tasks/{filename}"
        task.del_meta("task_list")
        owner = store.root_page
        mark(affected, old_folder)
    else:
        folder = Path(list_page.rel).parent.as_posix()
        new_rel = f"{folder}/{filename}"
        task.set_meta("task_list", list_page.uri)
        owner = list_page
        mark(affected, old_folder)
        mark(affected, folder)
    if new_rel != old_rel:
        store.move_page(task, new_rel)
        rewrite_paths(store, [(old_rel, new_rel)])
    add_member(owner, str(task.meta.get("title") or ""), task.uri, task.rel)


def set_parent(store: Store, task: Page, parent: Page | None) -> None:
    if task.kind != "task":
        raise Fail("parent is a task-only field")
    old = task.meta.get("parent")
    old = None if blank(old) else old
    new = parent.uri if parent else None
    if old == new:
        return
    if new and would_parent_cycle(store, task.uri, new):
        raise Fail("hierarchy cycle")
    if old:
        old_page = store.by_uri.get(old)
        if old_page is not None:
            remove_value(old_page, "sub_tasks", task.uri)
    task.set_meta("parent", new)
    if parent is not None:
        append_unique(parent, "sub_tasks", task.uri)


def add_dependency(store: Store, task: Page, blocker: dict) -> None:
    if task.kind != "task":
        raise Fail("dependency is a task-only field")
    if not blocker["cross"] and would_dep_cycle(store, task.uri, blocker["uri"]):
        raise Fail("dependency cycle")
    append_edge(task, blocker["uri"], "dependency")
    if not blocker["cross"]:
        append_edge(blocker["page"], task.uri, "blocks")


def remove_dependency(store: Store, task: Page, ref: str) -> None:
    if task.kind != "task":
        raise Fail("dependency is a task-only field")
    blocker = resolve_dependency(store, ref)
    if not remove_edge(store, task, blocker["uri"], "dependency"):
        raise Fail("dependency is not present")
    if not blocker["cross"] and blocker["page"] is not None:
        remove_edge(store, blocker["page"], task.uri, "blocks")


def task_only_flags(args) -> bool:
    return any(
        [
            args.status,
            args.body_path,
            args.related_node,
            args.assignees,
            args.clear_assignees,
            args.parent,
            args.clear_parent,
            args.add_dependency,
            args.remove_dependency,
        ]
    )


def update_page(store: Store, args, affected: list[str]) -> Page:
    page = store.resolve(args.id)
    if args.assignees and args.clear_assignees:
        raise Fail("pass only one of --assignees and --clear-assignees", code=2)
    if args.parent and args.clear_parent:
        raise Fail("pass only one of --parent and --clear-parent", code=2)
    if args.task_list and args.clear_task_list:
        raise Fail("pass only one of --task-list and --clear-task-list", code=2)
    if page.kind == "task-list" and (args.task_list or args.clear_task_list):
        raise Fail(
            "unsupported: reparenting or clearing task_list on a nested task-list is not supported in v0.8.0; use the manual update path",
            code=3,
        )
    if page.kind == "task-list" and task_only_flags(args):
        raise Fail("task-only patch on a task-list")
    if page.kind == "task" and args.status and args.status not in ALLOWED_STATUS:
        raise Fail("task_status must be open|in_progress|done|cancelled")
    # Resolve targets before mutation so a bad ref writes nothing.
    list_page = resolve_list_arg(store, args.task_list) if args.task_list else None
    if list_page is not None and page.kind == "task" and list_page.uri == store.root_page.uri:
        raise Fail("task_list set to the root task-list URI")
    parent = resolve_parent(store, args.parent) if args.parent else None
    blockers = [resolve_dependency(store, ref) for ref in (args.add_dependency or [])]
    if args.related_node and not exists_inside(store.root, norm_rel(args.related_node)):
        raise Fail("related_node does not exist")
    if args.body_path:
        body_path = norm_rel(args.body_path)
        if not exists_inside(store.root, body_path) or not (store.root / body_path).is_file():
            raise Fail("body_path does not exist")
    if args.title:
        rename_title(store, page, args.title, affected)
    if page.kind == "task":
        if args.status:
            page.set_meta("task_status", args.status)
        if args.clear_assignees:
            page.set_meta("assignees", [])
        elif args.assignees:
            page.set_meta("assignees", [one_line(item, "assignee") for item in args.assignees])
        if args.related_node:
            page.set_meta("related_node", norm_rel(args.related_node))
        if args.body_path:
            page.set_meta("body_path", norm_rel(args.body_path))
        if args.clear_parent:
            set_parent(store, page, None)
        elif parent is not None:
            set_parent(store, page, parent)
        if args.clear_task_list:
            set_membership(store, page, None, affected)
        elif list_page is not None:
            set_membership(store, page, list_page, affected)
        for blocker in blockers:
            add_dependency(store, page, blocker)
        for ref in args.remove_dependency or []:
            remove_dependency(store, page, ref)
    return page


def complete_page(store: Store, ref: str) -> Page:
    page = store.resolve(ref)
    if page.kind != "task":
        raise Fail("task-list cannot be completed")
    page.set_meta("task_status", "done")
    return page


def post_exists(store: Store, rel: str, overlay: dict[str, str | None]) -> bool:
    if rel in overlay:
        return overlay[rel] is not None
    return exists_inside(store.root, rel)


def validate_changed(store: Store, required: list[str], overlay: dict[str, str | None]) -> None:
    for page in store.pages.values():
        moved = page.original_rel is not None and page.original_rel != page.rel
        if page.original is not None and not page.meta_dirty and not page.body_dirty and not moved:
            continue
        for key in FORBIDDEN:
            if key in page.meta:
                raise Fail(f"forbidden key {key}")
        if page.kind == "task-list":
            for key in required:
                if not str(page.meta.get(key) or "").strip():
                    raise Fail(f"task-list missing required frontmatter {key}")
            if page is store.root_page and not blank(page.meta.get("task_list")):
                raise Fail("root omits task_list")
            tasks = page.meta.get("tasks")
            if tasks is not None and not isinstance(tasks, list):
                raise Fail("tasks must be a list of atlas:// URIs")
        elif page.kind == "task":
            for key in TASK_REQUIRED:
                if key not in page.meta:
                    raise Fail(f"task missing {key}")
            if page.meta.get("type") != "task":
                raise Fail("type must be task")
            if page.meta.get("task_status") not in ALLOWED_STATUS:
                raise Fail("task_status must be open|in_progress|done|cancelled")
            parsed = parse_uri(str(page.meta.get("task_id") or ""))
            if not parsed or parsed[0] != store.atlas_id:
                raise Fail("task_id must be atlas://<atlas_id>/tasks/<ULID>")
            if not isinstance(page.meta.get("assignees"), list):
                raise Fail("assignees must be a list")
            if not isinstance(page.meta.get("sub_tasks"), list):
                raise Fail("sub_tasks must be a list")
            if not isinstance(page.meta.get("relates_to"), list):
                raise Fail("relates_to must be a list")
            if not str(page.meta.get("title") or "").strip():
                raise Fail("title is required")
            if not str(page.meta.get("created") or "").strip():
                raise Fail("created is required")
            tl = page.meta.get("task_list")
            if not blank(tl) and tl == store.root_page.uri:
                raise Fail("task never stores root URI")
            body_path = str(page.meta.get("body_path") or "")
            related = str(page.meta.get("related_node") or "")
            if not post_exists(store, body_path, overlay) or not (store.root / body_path).suffix:
                if not post_exists(store, body_path, overlay):
                    raise Fail("body_path does not exist")
            if not post_exists(store, related, overlay):
                raise Fail("related_node does not exist")
        page.output_text()


def compliance(store: Store, touched: set[str]) -> None:
    if store.root_page is None:
        raise Fail("tasks/index.md missing or not type: task-list; run mount-overlay or migrate")
    root = store.root_page
    if not blank(root.meta.get("task_list")):
        raise Fail("root omits task_list")
    seen: dict[str, str] = {}
    for page in store.pages.values():
        if not page.ulid:
            continue
        if page.ulid in seen:
            raise Fail("ULID collision")
        seen[page.ulid] = page.uri
    root_uris = list(root.meta.get("tasks") or [])
    if not isinstance(root_uris, list):
        raise Fail("tasks must be a list of atlas:// URIs")

    def walk(list_page: Page, seen_lists: set[str]) -> None:
        if list_page.uri in seen_lists:
            raise Fail("list-membership cycle")
        seen_lists.add(list_page.uri)
        uris = list_page.meta.get("tasks") or []
        if not isinstance(uris, list):
            raise Fail("tasks must be a list of atlas:// URIs")
        folder = Path(list_page.rel).parent.as_posix()
        for uri in uris:
            parsed = parse_uri(uri) if isinstance(uri, str) else None
            if not parsed or parsed[0] != store.atlas_id:
                raise Fail("tasks entries must be atlas:// URIs")
            member = store.by_uri.get(uri)
            if member is None or member.kind not in ("task", "task-list"):
                raise Fail("membership both sides disagree")
            if not member.rel.startswith(folder + "/"):
                raise Fail("member is not inside the list folder")
            if member.kind == "task":
                tl = member.meta.get("task_list")
                if list_page is root:
                    if not blank(tl):
                        raise Fail("loose task must omit task_list")
                else:
                    if tl != list_page.uri:
                        raise Fail("membership both sides disagree")
                    if uri in root_uris:
                        raise Fail("task both in a child list and loose on root")
            else:
                if member.meta.get("task_list") != list_page.uri:
                    raise Fail("membership both sides disagree")
                walk(member, seen_lists)

    walk(root, set())
    root_set = set(root_uris)
    for page in store.pages.values():
        if page.kind != "task" or page is root:
            continue
        tl = page.meta.get("task_list")
        if blank(tl) or "task_list" not in page.meta:
            if page.uri not in root_set:
                raise Fail("membership both sides disagree")
        else:
            if tl == root.uri:
                raise Fail("task never stores root URI")
            owner = store.by_uri.get(tl)
            if owner is None or page.uri not in (owner.meta.get("tasks") or []):
                raise Fail("membership both sides disagree")
    for uri in touched:
        page = store.by_uri.get(uri)
        if page is None or page.kind != "task":
            continue
        parent = page.meta.get("parent")
        if not blank(parent):
            parent_page = store.by_uri.get(parent)
            if parent_page is None or page.uri not in (parent_page.meta.get("sub_tasks") or []):
                raise Fail("hierarchy back-link missing")
        for child_uri in page.meta.get("sub_tasks") or []:
            child = store.by_uri.get(child_uri)
            if child is None or child.meta.get("parent") != page.uri:
                raise Fail("hierarchy back-link missing")
        for edge in page.meta.get("relates_to") or []:
            if not isinstance(edge, dict):
                continue
            kind = edge.get("kind")
            target = edge.get("path")
            parsed = parse_uri(target) if isinstance(target, str) else None
            if kind == "dependency":
                if parsed and parsed[0] != store.atlas_id:
                    continue
                blocker = store.by_uri.get(edge_uri(store, target) or "")
                if blocker is None or blocker.kind != "task":
                    raise Fail("dependency back-link missing")
                if not any(
                    isinstance(item, dict)
                    and item.get("kind") == "blocks"
                    and edge_uri(store, item.get("path")) == page.uri
                    for item in (blocker.meta.get("relates_to") or [])
                ):
                    raise Fail("dependency back-link missing")
            if kind == "blocks":
                waiter = store.by_uri.get(edge_uri(store, target) or "")
                if waiter is None or waiter.kind != "task":
                    raise Fail("dependency back-link missing")
                if not any(
                    isinstance(item, dict)
                    and item.get("kind") == "dependency"
                    and edge_uri(store, item.get("path")) == page.uri
                    for item in (waiter.meta.get("relates_to") or [])
                ):
                    raise Fail("dependency back-link missing")


def derived_blocked(store: Store, page: Page) -> bool:
    # pin 9
    if page.kind != "task":
        return False
    for edge in page.meta.get("relates_to") or []:
        if not isinstance(edge, dict) or edge.get("kind") != "dependency":
            continue
        target = edge.get("path")
        parsed = parse_uri(target) if isinstance(target, str) else None
        if parsed is None or parsed[0] != store.atlas_id:
            return True
        other = store.by_ulid.get(parsed[1])
        if other is None or other.kind != "task":
            return True
        if other.meta.get("task_status") in ("open", "in_progress"):
            return True
    return False


def index_owned(text: str) -> bool:
    try:
        meta, _body = lfi().frontmatter(text)
    except lfi().FrontmatterError:
        return False
    return meta.get("generated_by") == lfi().MARKER


def plan_indexes(store: Store, affected: list[str]) -> tuple[list[dict], list[dict], list[str]]:
    # pin 23
    refresh = []
    ops = []
    warnings = []
    overlay = store.overlay()
    for folder in affected:
        list_rel = None
        for page in store.pages.values():
            if page.kind == "task-list" and Path(page.rel).parent.as_posix() == folder:
                list_rel = page.rel
                break
        if list_rel is None:
            raise Fail("no task-list page in affected folder")
        content, err = lfi().render_list_folder_index(store.root, list_rel, overlay)
        if err:
            raise Fail(err)
        idx_rel = f"{folder}/index.md"
        old_rel, old_text = store.relocated_index.get(folder, (None, None))
        existing = None
        existing_rel = idx_rel
        if old_rel:
            existing = old_text
            existing_rel = old_rel
        else:
            path = store.root / idx_rel
            if path.is_symlink():
                raise Fail("refuse symlink or path outside root")
            if path.is_file() and contained(store.root, path):
                existing = path.read_text(encoding="utf-8")
        if existing is not None and not index_owned(existing):
            refresh.append({"path": idx_rel, "action": "skip-foreign"})
            warnings.append(f"hand-written index.md left untouched: {idx_rel}")
            if old_rel and old_text is not None:
                store.extra_moves.append((old_rel, idx_rel, old_text))
            continue
        if existing == content and not old_rel:
            refresh.append({"path": idx_rel, "action": "ok"})
            continue
        action = "update" if existing is not None and not old_rel else "create"
        refresh.append({"path": idx_rel, "action": action})
        op = {"action": action, "path": idx_rel, "content": content}
        if old_rel:
            op["delete"] = old_rel
        ops.append(op)
    return refresh, ops, warnings


def collect_ops(store: Store, index_ops: list[dict]) -> tuple[list[dict], list[tuple]]:
    changes = []
    write_ops = []
    index_paths = {op["path"] for op in index_ops}
    for page in store.pages.values():
        moved = page.original_rel is not None and page.original_rel != page.rel
        new = page.original is None
        dirty = page.meta_dirty or page.body_dirty
        if not (new or moved or dirty):
            continue
        content = page.output_bytes()
        if new:
            changes.append({"action": "create", "path": page.rel})
            write_ops.append(("create", page.rel, None, content))
        elif moved:
            changes.append({"action": "move", "path": page.rel, "from": page.original_rel})
            write_ops.append(("move", page.rel, page.original_rel, content))
        else:
            changes.append({"action": "update", "path": page.rel})
            write_ops.append(("update", page.rel, None, content))
    for old, new, text in store.extra_moves:
        if new in index_paths:
            changes.append({"action": "delete", "path": old})
            write_ops.append(("delete", old, None, None))
            continue
        changes.append({"action": "move", "path": new, "from": old})
        write_ops.append(("move", new, old, text.encode("utf-8")))
    for op in index_ops:
        changes.append({"action": op["action"], "path": op["path"]})
        write_ops.append((op["action"], op["path"], None, op["content"].encode("utf-8")))
        if op.get("delete"):
            changes.append({"action": "delete", "path": op["delete"]})
            write_ops.append(("delete", op["delete"], None, None))
    return changes, write_ops


def read_bytes(root: Path, rel: str) -> bytes | None:
    path = root / rel
    if path.is_symlink() or not path.is_file() or not contained(root, path):
        if path.is_symlink():
            raise Fail("refuse symlink or path outside root")
        return None
    return path.read_bytes()


def atomic_write(root: Path, rel: str, data: bytes) -> None:
    dest = safe_path(root, rel)
    parent = dest.parent
    if not parent.exists():
        cur = root
        for part in Path(rel).parts[:-1]:
            cur = cur / part
            if cur.is_symlink():
                raise Fail("refuse symlink or path outside root")
            if not cur.exists():
                cur.mkdir(mode=0o755)
            if cur.is_symlink() or not contained(root, cur):
                raise Fail("refuse symlink or path outside root")
    if dest.is_symlink():
        raise Fail("refuse symlink or path outside root")
    fd, tmp_name = tempfile.mkstemp(prefix=".tasks-", suffix=".tmp", dir=str(parent))
    try:
        os.write(fd, data)
        os.fsync(fd)
    finally:
        os.close(fd)
    try:
        if dest.is_symlink():
            raise Fail("refuse symlink or path outside root")
        os.replace(tmp_name, dest)
    except Exception:
        try:
            os.unlink(tmp_name)
        except OSError:
            pass
        raise


def safe_unlink(root: Path, rel: str) -> None:
    path = safe_path(root, rel)
    if path.is_symlink():
        raise Fail("refuse symlink or path outside root")
    if not path.exists():
        return
    if path.is_dir():
        raise Fail("refuse to unlink a directory")
    path.unlink()


def prune_empty(root: Path, rel: str) -> None:
    parent = (root / rel).parent
    stop = {root.resolve(), (root / "tasks").resolve()}
    while parent.exists() and parent.resolve() not in stop:
        if parent.is_symlink() or not parent.is_dir() or not contained(root, parent):
            break
        if any(parent.iterdir()):
            break
        try:
            parent.rmdir()
        except OSError:
            break
        parent = parent.parent


def apply_ops(root: Path, write_ops: list[tuple]) -> None:
    snapshots: dict[str, bytes | None] = {}
    written: list[str] = []
    deleted: list[str] = []
    try:
        for action, path, src, content in write_ops:
            if action in ("create", "update", "move"):
                if path not in snapshots:
                    snapshots[path] = read_bytes(root, path)
                atomic_write(root, path, content)
                written.append(path)
        for action, path, src, content in write_ops:
            victim = src if action == "move" else path if action == "delete" else None
            if victim is None:
                continue
            if victim not in snapshots:
                snapshots[victim] = read_bytes(root, victim)
            safe_unlink(root, victim)
            deleted.append(victim)
    except Exception as e:
        for rel in reversed(deleted):
            data = snapshots.get(rel)
            if data is not None:
                try:
                    atomic_write(root, rel, data)
                except Exception:
                    pass
        for rel in reversed(written):
            data = snapshots.get(rel)
            try:
                if data is None:
                    safe_unlink(root, rel)
                else:
                    atomic_write(root, rel, data)
            except Exception:
                pass
        raise Fail("write failed; rolled back") from e
    for rel in deleted:
        prune_empty(root, rel)


def touched_uris(store: Store) -> set[str]:
    out = set()
    for page in store.pages.values():
        moved = page.original_rel is not None and page.original_rel != page.rel
        if page.original is None or page.meta_dirty or page.body_dirty or moved:
            if page.uri:
                out.add(page.uri)
    return out


def finish(command: str, dry: bool, store: Store, page: Page, affected: list[str]) -> dict:
    required = load_overlay_required(store.root)
    overlay = store.overlay()
    validate_changed(store, required, overlay)
    compliance(store, touched_uris(store))
    refresh, index_ops, warnings = plan_indexes(store, affected)
    # Index bytes are not part of the page overlay; re-check after planning.
    changes, write_ops = collect_ops(store, index_ops)
    if not dry:
        apply_ops(store.root, write_ops)
    return {
        "ok": True,
        "command": command,
        "dry_run": dry,
        "atlas_id": store.atlas_id,
        "task_id": page.uri,
        "ulid": page.ulid,
        "title": page.meta.get("title"),
        "kind": "task-list" if page.kind == "task-list" else "task",
        "path": page.rel,
        "body_path": page.meta.get("body_path") if page.kind == "task" else None,
        "task_list": None if blank(page.meta.get("task_list")) else page.meta.get("task_list"),
        "parent": None if page.kind != "task" or blank(page.meta.get("parent")) else page.meta.get("parent"),
        "derived_blocked": derived_blocked(store, page) if page.kind == "task" else False,
        "changes": changes,
        "index_refresh": refresh,
        "warnings": warnings,
    }


def cmd_add(args) -> dict:
    root = Path(args.root).resolve()
    store = load_store(root)
    affected: list[str] = []
    if args.kind == "task-list":
        page = add_list(store, args, affected)
    else:
        page = add_task(store, args, affected)
    return finish("add", args.dry_run, store, page, affected)


def cmd_update(args) -> dict:
    root = Path(args.root).resolve()
    store = load_store(root)
    affected: list[str] = []
    page = update_page(store, args, affected)
    if page.kind == "task":
        folder = Path(page.rel).parent.as_posix()
        if folder != "tasks" and (args.title or args.task_list or args.clear_task_list):
            mark(affected, folder)
    return finish("update", args.dry_run, store, page, affected)


def cmd_complete(args) -> dict:
    root = Path(args.root).resolve()
    store = load_store(root)
    page = complete_page(store, args.id)
    return finish("complete", args.dry_run, store, page, [])


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="tasks.py",
        description="Write atlas-tasks add, update, and complete. Prints one JSON receipt.",
    )
    sub = parser.add_subparsers(dest="command", required=True)
    add = sub.add_parser("add", help="Create a task or a task list")
    add.add_argument("--root", required=True)
    add.add_argument("--title", required=True)
    add.add_argument("--kind", default="task", choices=["task", "task-list"])
    add.add_argument("--related-node")
    add.add_argument("--body-path")
    add.add_argument("--body")
    add.add_argument("--task-id")
    add.add_argument("--status")
    add.add_argument("--assignee", action="append")
    add.add_argument("--parent")
    add.add_argument("--task-list")
    add.add_argument("--depends-on", action="append")
    add.add_argument("--created")
    add.add_argument("--dry-run", action="store_true")
    upd = sub.add_parser("update", help="Patch a task or task list")
    upd.add_argument("--root", required=True)
    upd.add_argument("--id", required=True, help="atlas:// URI, ULID, or store-relative pointer path")
    upd.add_argument("--title")
    upd.add_argument("--status")
    upd.add_argument("--assignees", action="append")
    upd.add_argument("--clear-assignees", action="store_true")
    upd.add_argument("--parent")
    upd.add_argument("--clear-parent", action="store_true")
    upd.add_argument("--task-list")
    upd.add_argument("--clear-task-list", action="store_true")
    upd.add_argument("--add-dependency", action="append")
    upd.add_argument("--remove-dependency", action="append")
    upd.add_argument("--body-path")
    upd.add_argument("--related-node")
    upd.add_argument("--dry-run", action="store_true")
    comp = sub.add_parser("complete", help="Set task_status done on a task")
    comp.add_argument("--root", required=True)
    comp.add_argument("--id", required=True, help="atlas:// URI, ULID, or store-relative pointer path")
    comp.add_argument("--dry-run", action="store_true")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        if args.command == "add":
            receipt = cmd_add(args)
        elif args.command == "update":
            receipt = cmd_update(args)
        elif args.command == "complete":
            receipt = cmd_complete(args)
        else:
            raise Fail("unknown command", code=2)
    except Fail as exc:
        if exc.code == 2:
            print(f"error: {exc.message}", file=sys.stderr)
            return 2
        message = exc.message if exc.message.startswith("fail-closed:") else f"fail-closed: {exc.message}"
        print(json.dumps({"ok": False, "command": args.command, "error": message}, ensure_ascii=False))
        return exc.code
    print(json.dumps(receipt, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
