"""Check all links in markdown files for validity.

Validates:
- Internal cross-references: target .md file exists
- Internal anchors: heading exists in target file
- External URLs: HEAD request returns 2xx/3xx
- Image/asset references: file exists on disk

Usage:
    python scripts/check_links.py [--no-external] [--files FILE ...]
    python scripts/check_links.py --docs-only
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
import urllib.error
import urllib.request
from pathlib import Path

# Markdown link patterns
# [text](url) and ![alt](url)
LINK_RE = re.compile(r"!?\[(?:[^\]]*)\]\(([^)]+)\)")
# Bare autolinks <https://...>
AUTOLINK_RE = re.compile(r"<(https?://[^>]+)>")
# HTML href/src attributes
HTML_ATTR_RE = re.compile(r'(?:href|src)="(https?://[^"]+)"')

# ATX headings: # Heading text
HEADING_RE = re.compile(r"^#{1,6}\s+(.+?)(?:\s+\{[^}]*\})?\s*$", re.MULTILINE)

# Skip patterns
SKIP_URL_PREFIXES = ("mailto:", "tel:", "javascript:", "{")
SKIP_EXTERNAL_DOMAINS = (
    "codecov.io",  # requires auth
    "img.shields.io",  # badge service, rate-limits
)


def slugify_heading(text: str) -> str:
    """Convert heading text to anchor slug (MkDocs/GitHub style)."""
    text = re.sub(r"[^\w\s-]", "", text.lower())
    text = re.sub(r"[\s]+", "-", text.strip())
    return text


def extract_headings(path: Path) -> set[str]:
    """Extract all heading anchors from a markdown file."""
    content = path.read_text(encoding="utf-8")
    return {slugify_heading(m.group(1)) for m in HEADING_RE.finditer(content)}


def extract_links(path: Path) -> list[tuple[int, str]]:
    """Extract all links from a markdown file as (line_number, url) pairs."""
    links: list[tuple[int, str]] = []
    content = path.read_text(encoding="utf-8")
    for i, line in enumerate(content.splitlines(), start=1):
        # Skip fenced code blocks
        if line.strip().startswith("```"):
            continue
        for match in LINK_RE.finditer(line):
            url = match.group(1).split(" ")[0]  # strip title
            links.append((i, url))
        for match in AUTOLINK_RE.finditer(line):
            links.append((i, match.group(1)))
        for match in HTML_ATTR_RE.finditer(line):
            links.append((i, match.group(1)))
    return links


def check_internal_link(url: str, source: Path, docs_dir: Path | None) -> str | None:
    """Check an internal (relative) link. Returns error message or None."""
    # Split anchor
    if "#" in url:
        file_part, anchor = url.split("#", 1)
    else:
        file_part, anchor = url, None

    if not file_part:
        # Pure anchor link (#section) — check in same file
        if anchor:
            headings = extract_headings(source)
            if anchor not in headings:
                return f"anchor #{anchor} not found in {source.name}"
        return None

    # Resolve relative to source file's directory
    target = (source.parent / file_part).resolve()

    # For docs cross-references, also try docs_dir
    if not target.exists() and docs_dir:
        target = (docs_dir / file_part).resolve()

    if not target.exists():
        return f"file not found: {file_part}"

    # Check anchor in target file
    if anchor and target.suffix == ".md":
        headings = extract_headings(target)
        if anchor not in headings:
            return f"anchor #{anchor} not found in {target.name}"

    return None


_url_cache: dict[str, str | None] = {}


def _check_url_curl(url: str) -> str | None:
    """Fallback: check URL via curl (bypasses TLS fingerprint blocking)."""
    try:
        result = subprocess.run(
            [
                "curl",
                "-sI",
                "-o",
                "/dev/null",
                "-w",
                "%{http_code}",
                "--max-time",
                "10",
                url,
            ],
            capture_output=True,
            text=True,
            timeout=15,
        )
        code = int(result.stdout.strip())
        if code >= 400:
            return f"HTTP {code}"
        return None
    except Exception as e:
        return str(e)


def _check_url_urllib(url: str) -> str | None:
    """Check URL via urllib. Returns error message or None."""
    headers = {
        "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
        "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
        "Accept": "text/html,application/xhtml+xml,*/*",
        "Accept-Language": "en-US,en;q=0.9",
    }
    for method in ("HEAD", "GET"):
        try:
            req = urllib.request.Request(url, method=method, headers=headers)
            with urllib.request.urlopen(req, timeout=10) as resp:  # noqa: S310
                if resp.status >= 400:
                    return f"HTTP {resp.status}"
                return None
        except urllib.error.HTTPError as e:
            if e.code == 405 and method == "HEAD":
                continue  # retry with GET
            if e.code == 403:
                return "HTTP 403"  # signal caller to try curl
            return f"HTTP {e.code}"
        except Exception as e:
            return str(e)
    return None  # pragma: no cover


def check_external_url(url: str) -> str | None:
    """Check an external URL is reachable. Returns error message or None."""
    if url in _url_cache:
        return _url_cache[url]

    for domain in SKIP_EXTERNAL_DOMAINS:
        if domain in url:
            _url_cache[url] = None
            return None

    err = _check_url_urllib(url)
    # CDNs (Akamai, Cloudflare) block Python's TLS fingerprint — fall back to curl
    if err == "HTTP 403":
        err = _check_url_curl(url)

    _url_cache[url] = err
    return err


def check_file(
    path: Path,
    *,
    check_external: bool = True,
    docs_dir: Path | None = None,
    verbose: bool = False,
) -> tuple[list[str], int, int, int]:
    """Check all links in a single file.

    Returns (errors, internal_count, external_count, skipped_count).
    """
    errors: list[str] = []
    links = extract_links(path)
    n_internal = 0
    n_external = 0
    n_skipped = 0

    for lineno, url in links:
        # Skip non-link patterns
        if any(url.startswith(p) for p in SKIP_URL_PREFIXES):
            n_skipped += 1
            continue

        # MkDocs button syntax: url{ .md-button }
        url = url.split("{")[0].strip()

        if url.startswith(("http://", "https://")):
            n_external += 1
            if check_external:
                if verbose:
                    print(f"    GET {url}", flush=True)
                err = check_external_url(url)
                if err:
                    errors.append(f"  {path}:{lineno}: {url} -> {err}")
                elif verbose:
                    print("      -> OK", flush=True)
        else:
            n_internal += 1
            err = check_internal_link(url, path, docs_dir)
            if err:
                errors.append(f"  {path}:{lineno}: {url} -> {err}")

    return errors, n_internal, n_external, n_skipped


def main() -> int:
    parser = argparse.ArgumentParser(description="Check links in markdown files")
    parser.add_argument(
        "--no-external",
        action="store_true",
        help="Skip external URL checks (faster)",
    )
    parser.add_argument(
        "--docs-only",
        action="store_true",
        help="Only check docs/ directory",
    )
    parser.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        help="Show each URL being checked",
    )
    parser.add_argument(
        "files",
        nargs="*",
        type=Path,
        help="Specific files to check (default: all .md files)",
    )
    args = parser.parse_args()

    root = Path.cwd()
    docs_dir = root / "docs"

    if args.files:
        files = args.files
    elif args.docs_only:
        files = sorted(docs_dir.glob("**/*.md"))
    else:
        files = sorted(
            p
            for p in root.glob("**/*.md")
            if ".claude" not in p.parts
            and ".venv" not in p.parts
            and "node_modules" not in p.parts
            and "site" not in p.parts
        )

    all_errors: list[str] = []
    total_internal = 0
    total_external = 0
    total_skipped = 0

    for path in files:
        rel = path.relative_to(root) if path.is_relative_to(root) else path
        file_docs_dir = docs_dir if path.is_relative_to(docs_dir) else None
        errors, n_int, n_ext, n_skip = check_file(
            path,
            check_external=not args.no_external,
            docs_dir=file_docs_dir,
            verbose=args.verbose,
        )
        total_internal += n_int
        total_external += n_ext
        total_skipped += n_skip

        status = f"FAIL ({len(errors)})" if errors else "ok"
        mode = (
            "internal only"
            if args.no_external
            else f"{n_int} internal, {n_ext} external"
        )
        print(f"  {rel} ... {mode} ... {status}", flush=True)

        all_errors.extend(errors)

    # Summary
    print()
    checked_ext = 0 if args.no_external else total_external
    unique_ext = len(_url_cache)
    print(
        f"Checked {len(files)} files: "
        f"{total_internal} internal, "
        f"{checked_ext} external ({unique_ext} unique URLs)"
    )
    if total_skipped:
        print(f"Skipped {total_skipped} non-http links (mailto, anchors, etc.)")

    if all_errors:
        print(f"\nBroken: {len(all_errors)}")
        for err in all_errors:
            print(err)
        return 1

    print("All links OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
