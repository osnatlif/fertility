import re
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).parent

# matches a memoryview-typed Cython parameter: e.g. "double[:, :, :, :] h_s_emax"
PARAM_RE = re.compile(r"(?:double|int|float|long|cdef\s+\w+)\s*\[((?:\s*:\s*,?)+)\]\s*(\w+)")
FUNC_RE = re.compile(r"^\s*(?:cdef|cpdef|def)\s+[^\(]*\(([^)]*(?:\n[^)]*)*?)\)", re.MULTILINE)

def dim_count(spec):
    # spec like " :, :, :, : " -> count colons
    return spec.count(":")

def parse_signatures(path):
    text = path.read_text()
    sigs = []
    # use regex to find function signatures across lines
    for m in FUNC_RE.finditer(text):
        params_blob = m.group(1)
        for pm in PARAM_RE.finditer(params_blob):
            sigs.append((pm.group(2), dim_count(pm.group(1))))
    return sigs

def main():
    by_file = {}
    for f in sorted(ROOT.glob("*.pyx")) + sorted(ROOT.glob("*.pxd")):
        by_file[f.name] = parse_signatures(f)

    # 1) Check .pyx vs .pxd consistency
    print("=" * 70)
    print("PXD/PYX MISMATCHES")
    print("=" * 70)
    any_mismatch = False
    pxd_files = [n for n in by_file if n.endswith(".pxd")]
    for pxd in pxd_files:
        pyx = pxd[:-4] + ".pyx"
        if pyx not in by_file:
            continue
        pxd_params = {n: d for n, d in by_file[pxd]}
        pyx_params = {n: d for n, d in by_file[pyx]}
        common = set(pxd_params) & set(pyx_params)
        for name in sorted(common):
            if pxd_params[name] != pyx_params[name]:
                any_mismatch = True
                print(f"  [MISMATCH] {pxd}/{pyx}: {name}  pxd={pxd_params[name]}D  pyx={pyx_params[name]}D")
    if not any_mismatch:
        print("  (none)")

    # 2) Same parameter name across files - report distinct dim counts
    print()
    print("=" * 70)
    print("CROSS-FILE PARAM DIMENSION INCONSISTENCIES")
    print("=" * 70)
    by_name = defaultdict(set)
    for fname, sigs in by_file.items():
        for n, d in sigs:
            by_name[n].add((fname, d))
    any_cross = False
    for name in sorted(by_name):
        dims = {d for _, d in by_name[name]}
        if len(dims) > 1:
            any_cross = True
            print(f"  [{name}] dim counts seen: {sorted(dims)}")
            for fname, d in sorted(by_name[name]):
                print(f"    {fname}: {d}D")
    if not any_cross:
        print("  (none)")

if __name__ == "__main__":
    main()
