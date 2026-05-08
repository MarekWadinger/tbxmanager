#!/usr/bin/env python3
"""Audit tbxmanager-registry packages for missing subdependencies.

Downloads each package's latest non-yanked version, extracts it,
and scans .m files for references to other registered packages.

Usage:
    python scripts/audit_dependencies.py [--pkg NAME] [--dry-run]
"""

from __future__ import annotations

import argparse
import io
import json
import re
import ssl
import tarfile
import tempfile
import urllib.request
import zipfile
from pathlib import Path

REGISTRY = Path(__file__).resolve().parent.parent / "tbxmanager-registry" / "packages"

# Known function/class signatures that belong to specific packages.
# Maps package_name -> list of regex patterns (case-sensitive).
SIGNATURES: dict[str, list[str]] = {
    "yalmip": [
        r"\bsdpvar\b",
        r"\boptimize\b",
        r"\bsolvesdp\b",
        r"\bsdpsettings\b",
        r"\buncertain\b",
        r"\bsolvesos\b",
        r"\bbisection\b",
        r"\boptimizer\b",
        r"\bvalue\(",  # value() is generic but combined with sdpvar context
    ],
    "sedumi": [r"\bsedumi\b"],
    "mpt": [
        r"\bPolyhedron\b",
        r"\bmpt_init\b",
        r"\bmptopt\b",
        r"\bSystemSignal\b",
        r"\bEMPCController\b",
        r"\bOnlineMPC\b",
        r"\bLTISystem\b",
        r"\bPWASystem\b",
        r"\bMLDSystem\b",
        r"\bUnionOfPolyhedra\b",
        r"\bBinTreePolyUnion\b",
    ],
    "cddmex": [r"\bcddmex\b"],
    "lcp": [r"\blcp\b", r"\bmpt_mlcp\b"],
    "glpkmex": [r"\bglpkmex\b"],
    "fourier": [r"\bfourier\b"],
    "espresso": [r"\bespresso\b"],
    "hysdel": [r"\bhysdel\b"],
    "elab": [
        r"\belab\b",
        r"\bElabInit\b",
    ],
    "matlabjson": [r"\bloadjson\b", r"\bsavejson\b"],
    "hashtable": [r"\bhashtable\b"],
    "mpt2": [r"\bmpt_init\b"],  # mpt2 also uses mpt_init
    "qpspline": [r"\bQPspline\b"],
    "oasesmex": [r"\bqpOASES\b"],
    "clpmex": [r"\bclp\b"],
    "flexy": [r"\bflexy\b"],
    "flexy2": [r"\bflexy2\b"],
    "dynopt": [r"\bdynopt\b", r"\bdynopc\b"],
}


def get_all_package_names() -> list[str]:
    """Return sorted list of all registered package names."""
    names = []
    for d in sorted(REGISTRY.iterdir()):
        pj = d / "package.json"
        if pj.exists():
            data = json.loads(pj.read_text())
            names.append(data["name"])
    return names


def get_latest_non_yanked(pkg_path: Path) -> tuple[str, dict] | None:
    """Return (version, version_data) for the latest non-yanked version."""
    data = json.loads((pkg_path / "package.json").read_text())
    versions = data.get("versions", {})
    latest_ver = None
    latest_data = None
    for ver, vdata in versions.items():
        if isinstance(vdata, str):
            continue
        if vdata.get("yanked", False):
            continue
        latest_ver = ver
        latest_data = vdata
    if latest_ver is None:
        return None
    return latest_ver, latest_data


def download_and_extract(url: str, dest: Path) -> bool:
    """Download archive from url and extract to dest. Returns True on success."""
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE

    try:
        req = urllib.request.Request(
            url, headers={"User-Agent": "tbxmanager-audit/1.0"}
        )
        with urllib.request.urlopen(req, timeout=30, context=ctx) as resp:
            data = resp.read()
    except Exception as e:
        print(f"    DOWNLOAD FAILED: {e}")
        return False

    # Single .m file
    if url.endswith(".m"):
        dest.mkdir(parents=True, exist_ok=True)
        (dest / Path(url).name).write_bytes(data)
        return True

    # Try zip first, then tar
    try:
        with zipfile.ZipFile(io.BytesIO(data)) as zf:
            zf.extractall(dest)
        return True
    except zipfile.BadZipFile:
        pass

    try:
        with tarfile.open(fileobj=io.BytesIO(data)) as tf:
            tf.extractall(dest, filter="data")
        return True
    except tarfile.TarError, Exception:
        pass

    # Try gzip + tar
    try:
        import gzip

        decompressed = gzip.decompress(data)
        with tarfile.open(fileobj=io.BytesIO(decompressed)) as tf:
            tf.extractall(dest, filter="data")
        return True
    except Exception:
        pass

    print(f"    EXTRACT FAILED: unknown archive format for {url}")
    return False


def strip_comments(text: str) -> str:
    """Remove MATLAB line comments (lines starting with % or inline %)."""
    lines = []
    for line in text.splitlines():
        # Remove inline comments (naive: doesn't handle % inside strings)
        idx = line.find("%")
        if idx >= 0:
            line = line[:idx]
        lines.append(line)
    return "\n".join(lines)


def scan_m_files(
    pkg_dir: Path, pkg_name: str, all_packages: list[str]
) -> dict[str, list[str]]:
    """Scan all .m files in pkg_dir for references to other packages.

    Returns {dependency_name: [evidence_strings]}.
    """
    deps: dict[str, list[str]] = {}
    m_files = list(pkg_dir.rglob("*.m"))

    if not m_files:
        return deps

    for mf in m_files:
        try:
            text = mf.read_text(errors="replace")
        except Exception:
            continue

        code = strip_comments(text)
        rel_path = mf.relative_to(pkg_dir)

        # Check signature-based detection
        for dep_pkg, patterns in SIGNATURES.items():
            if dep_pkg == pkg_name:
                continue  # skip self-references
            if dep_pkg in deps:
                continue  # already found
            for pat in patterns:
                matches = re.findall(pat, code)
                if matches:
                    deps.setdefault(dep_pkg, []).append(f"{rel_path}: {matches[0]}")
                    break  # one match per package per file is enough

        # Check for tbxmanager install/require references
        for other in all_packages:
            if other == pkg_name or other in deps:
                continue
            # Look for string references like 'tbxmanager install <other>'
            # or addpath references containing the package name
            tbx_pat = rf"""tbxmanager\s*\(\s*['"]install['"]\s*,\s*['"]{re.escape(other)}['"]"""
            if re.search(tbx_pat, code):
                deps.setdefault(other, []).append(f"{rel_path}: tbxmanager install")

            # Check for addpath with package name
            addpath_pat = rf"""addpath\s*\([^)]*{re.escape(other)}[^)]*\)"""
            if re.search(addpath_pat, code):
                deps.setdefault(other, []).append(f"{rel_path}: addpath reference")

    return deps


def audit_package(
    pkg_name: str, all_packages: list[str], dry_run: bool = False
) -> dict:
    """Audit a single package. Returns result dict."""
    pkg_path = REGISTRY / pkg_name
    result = {"name": pkg_name, "status": "ok", "version": "", "deps": {}}

    info = get_latest_non_yanked(pkg_path)
    if info is None:
        result["status"] = "all_yanked"
        return result

    ver, vdata = info
    result["version"] = ver

    # Get first available platform URL
    platforms = vdata.get("platforms", {})
    # Prefer 'all', then current platform, then any
    url = None
    for plat_key in ["all", "maca64", "maci64", "glnxa64", "win64"]:
        if plat_key in platforms:
            url = platforms[plat_key].get("url")
            if url:
                break
    if url is None:
        # Take first available
        for pdata in platforms.values():
            url = pdata.get("url")
            if url:
                break

    if url is None:
        result["status"] = "no_url"
        return result

    if dry_run:
        result["status"] = "dry_run"
        result["url"] = url
        return result

    print(f"  Downloading {pkg_name}@{ver} from {url[:80]}...")

    with tempfile.TemporaryDirectory(prefix=f"tbx_audit_{pkg_name}_") as tmpdir:
        dest = Path(tmpdir) / "pkg"
        if not download_and_extract(url, dest):
            result["status"] = "download_failed"
            result["url"] = url
            return result

        deps = scan_m_files(dest, pkg_name, all_packages)
        result["deps"] = {k: v for k, v in sorted(deps.items())}

    return result


def main() -> None:
    parser = argparse.ArgumentParser(description="Audit registry for missing deps")
    parser.add_argument("--pkg", help="Audit only this package")
    parser.add_argument(
        "--dry-run", action="store_true", help="List packages without downloading"
    )
    parser.add_argument(
        "--output", "-o", help="Write JSON report to file", default=None
    )
    args = parser.parse_args()

    all_packages = get_all_package_names()
    print(f"Registry has {len(all_packages)} packages\n")

    if args.pkg:
        packages_to_audit = [args.pkg]
    else:
        packages_to_audit = all_packages

    results = []
    for pkg_name in packages_to_audit:
        print(
            f"[{packages_to_audit.index(pkg_name) + 1}/{len(packages_to_audit)}] {pkg_name}"
        )
        result = audit_package(pkg_name, all_packages, dry_run=args.dry_run)

        if result["status"] == "all_yanked":
            print("  SKIPPED: all versions yanked\n")
        elif result["status"] == "download_failed":
            print("  FAILED: could not download\n")
        elif result["deps"]:
            print(f"  FOUND {len(result['deps'])} dependency(ies):")
            for dep, evidence in result["deps"].items():
                print(f"    -> {dep}: {evidence[0]}")
        else:
            print("  No dependencies detected")
        print()
        results.append(result)

    # Summary
    print("=" * 60)
    print("SUMMARY")
    print("=" * 60)
    for r in results:
        if r["status"] in ("all_yanked", "dry_run"):
            continue
        deps_str = ", ".join(r["deps"].keys()) if r["deps"] else "(none)"
        status = "" if r["status"] == "ok" else f" [{r['status']}]"
        print(f"  {r['name']}@{r['version']}: {deps_str}{status}")

    if args.output:
        out_path = Path(args.output)
        out_path.write_text(json.dumps(results, indent=2))
        print(f"\nReport written to {out_path}")


if __name__ == "__main__":
    main()
