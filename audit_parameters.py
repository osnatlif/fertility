import re
from pathlib import Path

ROOT = Path(__file__).parent

# matches lines like "p.taste_cg = 360.0" or "p.alpha0 = 0.541"
ASSIGN_RE = re.compile(r"^\s*p\.(\w+)\s*=", re.MULTILINE)

def collect_assigned():
    names = {}
    for f in [ROOT / "parameters.py"] + sorted((ROOT / "input").glob("parameters*.py")):
        if not f.exists():
            continue
        text = f.read_text()
        for m in ASSIGN_RE.finditer(text):
            names.setdefault(m.group(1), []).append(f.name)
    return names

def collect_usage_files():
    files = []
    for ext in ("*.pyx", "*.py"):
        files += sorted(ROOT.glob(ext))
        files += sorted((ROOT / "input").glob(ext))
    return files

def main():
    assigned = collect_assigned()
    usage_files = collect_usage_files()
    # Build big concatenated text - skip assignment files for the usage scan,
    # so a parameter that is *only* defined but never read shows up as unused.
    skip = {"parameters.py"} | {f.name for f in (ROOT / "input").glob("parameters*.py")}
    text_blob = ""
    for f in usage_files:
        if f.name in skip:
            continue
        text_blob += "\n" + f.read_text()

    unused = []
    for name in sorted(assigned):
        # match "p.<name>" but not "p.<name>X" where X is alphanumeric
        if not re.search(rf"\bp\.{re.escape(name)}\b", text_blob):
            unused.append(name)

    print("=" * 70)
    print(f"PARAMETERS DEFINED BUT NEVER READ ({len(unused)} of {len(assigned)})")
    print("=" * 70)
    if not unused:
        print("  (none)")
    else:
        for name in unused:
            sources = ", ".join(sorted(set(assigned[name])))
            print(f"  p.{name:30s}  (defined in: {sources})")

if __name__ == "__main__":
    main()
