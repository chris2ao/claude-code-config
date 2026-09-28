#!/usr/bin/env python3
# platform: portable
"""blog-set-cover.py - set coverImage/coverImageAlt in a blog post's YAML frontmatter.

Usage: python3 blog-set-cover.py <post.mdx> <slug> <alt-text>

Deterministic replacement for hand-editing: inserts (or replaces) exactly two lines
just before the closing frontmatter fence and touches nothing else. Used by the
blog-finalize stage of ~/.claude/workflows/blog-pipeline.js so that agent needs no
Edit access to the post. Prints a JSON result; exits non-zero on any failure.
"""
import json
import re
import sys

SLUG_RE = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")


def fail(msg):
    print(json.dumps({"ok": False, "error": msg}))
    sys.exit(1)


def main():
    if len(sys.argv) != 4:
        fail("usage: blog-set-cover.py <post.mdx> <slug> <alt-text>")
    path, slug, alt = sys.argv[1], sys.argv[2], sys.argv[3]
    if not SLUG_RE.match(slug):
        fail(f"invalid slug: {slug!r}")
    alt = " ".join(alt.split()).replace('"', "'")
    if not alt:
        fail("empty alt text")
    if "\u2014" in alt:
        fail("alt text contains an em dash")

    try:
        text = open(path, encoding="utf-8").read()
    except OSError as e:
        fail(f"cannot read {path}: {e}")

    lines = text.split("\n")
    if not lines or lines[0].strip() != "---":
        fail("post does not start with a frontmatter fence")
    try:
        close = next(i for i in range(1, len(lines)) if lines[i].strip() == "---")
    except StopIteration:
        fail("frontmatter has no closing fence")

    front = [ln for ln in lines[1:close] if not re.match(r"^(coverImage|coverImageAlt):", ln)]
    front += [f"coverImage: /blog/{slug}/infographic.png", f'coverImageAlt: "{alt}"']
    new_text = "\n".join([lines[0]] + front + lines[close:])

    with open(path, "w", encoding="utf-8") as fh:
        fh.write(new_text)

    # Verify: each key exactly once, fences intact
    check = open(path, encoding="utf-8").read().split("\n")
    close2 = next(i for i in range(1, len(check)) if check[i].strip() == "---")
    fm = check[1:close2]
    counts = {k: sum(1 for ln in fm if ln.startswith(k + ":")) for k in ("coverImage", "coverImageAlt")}
    ok = counts == {"coverImage": 1, "coverImageAlt": 1}
    print(json.dumps({"ok": ok, "counts": counts, "path": path}))
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
