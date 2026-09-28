#!/usr/bin/env python3
"""Phase 2 diff summary for /review. Deterministic; replaces the Haiku helper.
Emits the ===SECTION=== factual brief the orchestrator already parses.
Run: py -3 -X utf8 diff_brief.py --base <branch> --repo-dir <dir> [--head <ref>]
Facts only - no interpretation. Specialists read the full diff themselves; this is a convenience map.
"""
import argparse, subprocess, re

def git(args, cwd):
    return subprocess.run(["git", *args], cwd=cwd, capture_output=True,
                          text=True, encoding="utf-8", errors="replace").stdout

def classify(path):
    p = path.lower()
    base = p.rsplit("/", 1)[-1]
    if re.search(r"\.(test|spec)\.", base) or "/tests/" in p or "/__tests__/" in p or p.startswith("tests/"):
        return "test"
    if (base in ("package.json", "yarn.lock", "pnpm-lock.yaml", "requirements.txt",
                 "pyproject.toml", "cargo.toml", "go.mod", "go.sum", "package-lock.json")
            or base.endswith("-lock.json")):
        return "deps"
    if p.endswith(".sql") or "migrations/" in p:
        return "migration"
    if p.endswith((".md", ".rst")) or p.startswith("docs/") or "/docs/" in p:
        return "docs"
    if p.endswith(".tf") or "k8s/" in p or ".github/workflows/" in p:
        return "infra"
    if (p.endswith((".json", ".yaml", ".yml", ".toml")) or base.startswith(".env")
            or base.startswith("dockerfile") or base == "tsconfig.json"):
        return "config"
    if p.endswith((".tsx", ".jsx", ".css", ".scss")) or "components/" in p or "pages/" in p:
        return "frontend"
    if p.endswith((".py", ".rb", ".go", ".java")) or "routes/" in p or "controllers/" in p:
        return "backend"
    if p.endswith(".ts"):
        return "backend" if ("/server/" in p or "/api/" in p or "routes/" in p) else "frontend"
    return "other"

HOTSPOT_RE = re.compile(r"(^|/)(router\.[tj]s|urls\.py|App\.tsx|settings\.py|config/index\.[tj]s|"
                        r"index\.ts|flags\.ts|feature_flags\.py)$", re.I)
ENDPOINT_RE = re.compile(r"@app\.route|@router\.(get|post|put|patch|delete)|@(app|router)\.(get|post|put|patch|delete)|"
                         r"\b(app|router)\.(get|post|put|patch|delete)\s*\(")
ENVVAR_RE = re.compile(r"os\.environ(?:\.get)?\[?['\"]([A-Z][A-Z0-9_]+)['\"]|os\.getenv\(['\"]([A-Z][A-Z0-9_]+)['\"]|"
                       r"process\.env\.([A-Z][A-Z0-9_]+)")

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--base", required=True)
    ap.add_argument("--repo-dir", required=True)
    ap.add_argument("--head", default="HEAD")
    a = ap.parse_args()
    cwd = a.repo_dir
    rng = f"origin/{a.base}...{a.head}"

    branch = git(["rev-parse", "--abbrev-ref", "HEAD"], cwd).strip()
    stat = git(["diff", "--stat", rng], cwd).rstrip()
    name_status = [l for l in git(["diff", "--name-status", rng], cwd).splitlines() if l.strip()]
    names = [l.split("\t", 1)[1] for l in name_status if "\t" in l]
    added = [l.split("\t", 1)[1] for l in name_status if l[:1] == "A" and "\t" in l]
    diff = git(["diff", rng], cwd)
    truncated = len(diff) > 800_000
    added_lines = [l[1:] for l in diff.splitlines() if l.startswith("+") and not l.startswith("+++")]

    cats = {k: [] for k in ("frontend", "backend", "config", "migration", "docs", "test", "infra", "deps", "other")}
    for n in names:
        cats[classify(n)].append(n)

    hotspots = [n for n in names if HOTSPOT_RE.search(n)]
    new_migrations = [n for n in added if n.lower().endswith(".sql") or "migrations/" in n.lower()]
    endpoints = sorted({l.strip()[:120] for l in added_lines if ENDPOINT_RE.search(l)})
    envvars = sorted({m for line in added_lines for grp in ENVVAR_RE.findall(line) for m in grp if m})

    # best-effort dep deltas from changed manifest hunks
    deps_changed = []
    for dep_file in cats["deps"]:
        old, new = {}, {}
        for l in git(["diff", rng, "--", dep_file], cwd).splitlines():
            m = re.match(r'^([+-])\s*["\']?([A-Za-z0-9._\-/@]+)["\']?\s*[:=]+\s*["\']?[~^>=<]*([0-9][0-9A-Za-z.\-]*)', l)
            if m:
                (new if m.group(1) == "+" else old)[m.group(2)] = m.group(3)
        for k in sorted(set(old) | set(new)):
            if k in old and k in new and old[k] != new[k]:
                deps_changed.append(f"{k} {old[k]} -> {new[k]}")
            elif k in new and k not in old:
                deps_changed.append(f"{k} (added) -> {new[k]}")
            elif k in old and k not in new:
                deps_changed.append(f"{k} (removed)")

    out = []
    out.append("===META===")
    out.append(f"date: {git(['log','-1','--format=%cI',a.head], cwd).strip() or 'unknown'}")
    out.append(f"branch: {branch}")
    out.append(f"base: origin/{a.base}")
    out.append(f"repo: {cwd}")
    out.append("fetch_failed: false")
    out.append(f"truncated: {'true' if truncated else 'false'}")
    out.append("")
    out.append("===STATS===")
    out.append(stat)
    out.append("")
    out.append("===FILES_BY_CATEGORY===")
    for k in ("frontend", "backend", "config", "migration", "docs", "test", "infra", "deps", "other"):
        out.append(f"{k}: {len(cats[k])}")
        out.extend("  " + n for n in cats[k])
    out.append("")
    out.append("===HOTSPOTS===")
    out.extend(hotspots)
    out.append("")
    out.append("===NEW_OR_BUMPED_DEPS===")
    out.extend(deps_changed)
    out.append("")
    out.append("===NEW_MIGRATIONS===")
    out.extend(new_migrations)
    out.append("")
    out.append("===NEW_ENDPOINTS===")
    out.extend(endpoints)
    out.append("")
    out.append("===NEW_ENV_VARS===")
    out.extend(envvars)
    out.append("")
    out.append("===END===")
    print("\n".join(out))

if __name__ == "__main__":
    main()
