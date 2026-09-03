#!/usr/bin/env python3
"""Generate dist/manifest.json from the contents of the repository.

Dependencies are discovered by scanning require() calls rather than declared by
hand, so the manifest cannot drift from the source. Every path under src/ is a
module whose name is its dotted path relative to src/ -- exactly the string CC
resolves once moonman has vendored it next to the program that needs it.

    tools/gen_manifest.py                 write dist/manifest.json
    tools/gen_manifest.py --check         fail if the committed manifest is stale
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent

SCHEMA = 2
MANIFEST_PATH = "dist/manifest.json"
SRC_DIR = "src"
MOONMAN_DIR = "moonman"
MOONMAN_ENTRY = "moonman/main.lua"
MOONMAN_ENTRY_TARGET = "moonman.lua"
PACKAGE_METADATA = "moonman.json"
DEFAULT_REPO = "caboose1029/minecraft-cc"
DEFAULT_REF = "main"

# Matches require "x", require("x"), require('x') -- string literals only.
REQUIRE_RE = re.compile(r"""\brequire\s*\(?\s*(['"])([^'"]+)\1""")
VERSION_RE = re.compile(r"""return\s*['"]([^'"]+)['"]""")

# Module namespaces CC provides itself; never treated as repository deps.
BUILTIN_PREFIXES = ("cc.", "rom.")


def run_git(*args: str) -> str | None:
    try:
        result = subprocess.run(
            ["git", *args], cwd=REPO_ROOT, capture_output=True, text=True, check=True
        )
    except (subprocess.CalledProcessError, FileNotFoundError):
        return None
    return result.stdout.strip() or None


def detect_ref() -> str:
    ref = os.environ.get("GITHUB_REF_NAME") or run_git("rev-parse", "--abbrev-ref", "HEAD")
    if not ref or ref == "HEAD":
        return DEFAULT_REF
    return ref


def detect_repo() -> str:
    repo = os.environ.get("GITHUB_REPOSITORY")
    if repo:
        return repo
    url = run_git("remote", "get-url", "origin")
    if not url:
        return DEFAULT_REPO
    match = re.search(r"[:/]([^/:]+/[^/]+?)(?:\.git)?$", url)
    return match.group(1) if match else DEFAULT_REPO


def lua_files(directory: Path) -> list[Path]:
    if not directory.is_dir():
        return []
    return sorted(p for p in directory.rglob("*.lua") if p.is_file())


def rel(path: Path) -> str:
    return path.relative_to(REPO_ROOT).as_posix()


def module_name(source: str) -> str:
    """src/share/test/sharetest.lua -> share.test.sharetest"""
    stripped = source[len(SRC_DIR) + 1 :]
    stripped = stripped[: -len(".lua")]
    if stripped.endswith("/init"):
        stripped = stripped[: -len("/init")]
    return stripped.replace("/", ".")


def scan_requires(path: Path) -> list[str]:
    text = path.read_text(encoding="utf-8", errors="replace")
    seen, names = set(), []
    for _, name in REQUIRE_RE.findall(text):
        if name not in seen and not name.startswith(BUILTIN_PREFIXES):
            seen.add(name)
            names.append(name)
    return names


def read_version() -> str:
    version_file = REPO_ROOT / MOONMAN_DIR / "version.lua"
    if not version_file.is_file():
        return "0.0.0"
    match = VERSION_RE.search(version_file.read_text(encoding="utf-8"))
    return match.group(1) if match else "0.0.0"


def build_moonman_section() -> dict:
    files = []
    for path in lua_files(REPO_ROOT / MOONMAN_DIR):
        source = rel(path)
        target = MOONMAN_ENTRY_TARGET if source == MOONMAN_ENTRY else source
        files.append({"source": source, "target": target})
    # Entry first so a partial install still leaves a runnable /moonman.lua last.
    files.sort(key=lambda f: (f["target"] != MOONMAN_ENTRY_TARGET, f["source"]))
    return {"version": read_version(), "files": files}


def build_modules() -> dict[str, dict]:
    modules: dict[str, dict] = {}
    for path in lua_files(REPO_ROOT / SRC_DIR):
        modules[module_name(rel(path))] = {"source": rel(path), "_requires": scan_requires(path)}
    return modules


def resolve_dependencies(requires: list[str], modules: dict, exclude: set[str], warnings: list[str], owner: str) -> list[str]:
    """Keep the require names that name a real repository module."""
    deps = []
    for name in requires:
        if name in exclude:
            continue
        if name in modules:
            deps.append(name)
        elif name.startswith("share."):
            warnings.append(f"{owner}: requires unknown shared module '{name}'")
    return sorted(set(deps))


def package_entry(package_dir: Path, files: list[str], name: str) -> str | None:
    """Pick the file a package runs, preferring main.lua then <leaf>.lua."""
    leaf = name.rsplit("/", 1)[-1]
    for candidate in ("main.lua", f"{leaf}.lua"):
        if candidate in files:
            return candidate
    return files[0] if len(files) == 1 else None


def build_package(name: str, package_dir: Path, sources: list[Path], modules: dict, warnings: list[str]) -> dict | None:
    files = [{"source": rel(p), "target": p.relative_to(package_dir).as_posix()} for p in sources]
    targets = [f["target"] for f in files]
    own_modules = {module_name(f["source"]) for f in files}

    requires: list[str] = []
    for path in sources:
        requires.extend(scan_requires(path))

    metadata = {}
    metadata_path = package_dir / PACKAGE_METADATA
    if metadata_path.is_file():
        metadata = json.loads(metadata_path.read_text(encoding="utf-8"))

    entry = metadata.get("entry") or package_entry(package_dir, targets, name)
    if entry is None:
        warnings.append(f"package {name}: cannot determine an entry point; add {PACKAGE_METADATA}")
        return None
    if entry not in targets:
        warnings.append(f"package {name}: entry '{entry}' is not one of its files")
        return None

    dependencies = resolve_dependencies(requires, modules, own_modules, warnings, f"package {name}")
    for extra in metadata.get("dependencies", []):
        if extra not in dependencies:
            dependencies.append(extra)

    package = {"entry": entry, "files": files, "dependencies": sorted(dependencies)}
    if metadata.get("description"):
        package["description"] = metadata["description"]
    return package


def build_packages(modules: dict, warnings: list[str]) -> dict[str, dict]:
    packages: dict[str, dict] = {}

    pkg_root = REPO_ROOT / SRC_DIR / "pkg"
    for package_dir in sorted(p for p in pkg_root.glob("*") if p.is_dir()):
        sources = lua_files(package_dir)
        if sources:
            built = build_package(package_dir.name, package_dir, sources, modules, warnings)
            if built:
                packages[package_dir.name] = built

    player_root = REPO_ROOT / SRC_DIR / "player"
    for player_dir in sorted(p for p in player_root.glob("*") if p.is_dir()):
        for child in sorted(player_dir.iterdir()):
            name = f"{player_dir.name}/{child.stem if child.is_file() else child.name}"
            if child.is_file() and child.suffix == ".lua":
                built = build_package(name, child.parent, [child], modules, warnings)
            elif child.is_dir():
                sources = lua_files(child)
                built = build_package(name, child, sources, modules, warnings) if sources else None
            else:
                continue
            if built:
                packages[name] = built

    return packages


def build_manifest() -> tuple[dict, list[str]]:
    warnings: list[str] = []
    modules = build_modules()
    packages = build_packages(modules, warnings)

    published_modules = {}
    for name, entry in sorted(modules.items()):
        published_modules[name] = {
            "source": entry["source"],
            "dependencies": resolve_dependencies(
                entry["_requires"], modules, {name}, warnings, f"module {name}"
            ),
        }

    manifest = {
        "schema": SCHEMA,
        "generated_at": datetime.now(timezone.utc).replace(microsecond=0).isoformat(),
        "source": {
            "repo": detect_repo(),
            "ref": detect_ref(),
            "manifest_path": MANIFEST_PATH,
        },
        "moonman": build_moonman_section(),
        "modules": published_modules,
        "packages": dict(sorted(packages.items())),
    }
    return manifest, warnings


def serialise(manifest: dict) -> str:
    return json.dumps(manifest, indent=2, sort_keys=False) + "\n"


def comparable(text: str) -> str:
    """Drop generated_at so --check does not fail purely on the timestamp."""
    try:
        data = json.loads(text)
    except json.JSONDecodeError:
        return text
    data.pop("generated_at", None)
    return json.dumps(data, indent=2, sort_keys=False)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--check", action="store_true", help="exit non-zero if the committed manifest is stale")
    parser.add_argument("--output", default=MANIFEST_PATH, help="where to write the manifest")
    parser.add_argument("--ref", help="override the detected git ref")
    parser.add_argument("--repo", help="override the detected owner/name")
    options = parser.parse_args()

    manifest, warnings = build_manifest()
    if options.ref:
        manifest["source"]["ref"] = options.ref
    if options.repo:
        manifest["source"]["repo"] = options.repo

    for warning in warnings:
        print(f"warning: {warning}", file=sys.stderr)

    rendered = serialise(manifest)
    output_path = REPO_ROOT / options.output

    if options.check:
        if not output_path.is_file():
            print(f"{options.output} does not exist; run tools/gen_manifest.py", file=sys.stderr)
            return 1
        if comparable(output_path.read_text(encoding="utf-8")) != comparable(rendered):
            print(f"{options.output} is stale; run tools/gen_manifest.py", file=sys.stderr)
            return 1
        print(f"{options.output} is up to date")
        return 0

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(rendered, encoding="utf-8")
    print(
        f"wrote {options.output}: {len(manifest['moonman']['files'])} moonman files, "
        f"{len(manifest['modules'])} modules, {len(manifest['packages'])} packages "
        f"({manifest['source']['repo']}@{manifest['source']['ref']})"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
