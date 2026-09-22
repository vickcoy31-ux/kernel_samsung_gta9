#!/usr/bin/env bash
set -u

ROOT="$(git rev-parse --show-toplevel)"
OUT="$ROOT/debug-bridge/report"
mkdir -p "$OUT"

echo "GTA9 DEBUG BRIDGE" > "$OUT/README.txt"
echo "Collected: $(date -Is)" >> "$OUT/README.txt"
echo "Commit: $(git rev-parse HEAD 2>/dev/null || true)" >> "$OUT/README.txt"
echo "Branch: $(git branch --show-current)" >> "$OUT/README.txt"

git status --short > "$OUT/git-status.txt" 2>&1 || true
git remote -v > "$OUT/git-remotes.txt" 2>&1 || true

{
    echo "=== CONFIG ==="
    grep -R -n \
      -E 'CONFIG_BUILD_ARM64_DTB_OVERLAY_IMAGE|CONFIG_BUILD_ARM64_DTB_OVERLAY_IMAGE_NAMES|CONFIG_BUILD_ARM64_DTB_IMAGE_NAMES' \
      kernel/configs arch 2>/dev/null || true
} > "$OUT/dtbo-config.txt"

{
    echo "=== ODM_DIRS ==="
    grep -R -n -E '(^|[[:space:]])ODM_DIRS[[:space:]]*=' \
      --exclude-dir=.git . 2>/dev/null || true
    echo
    echo "=== REFERENCES ==="
    grep -R -n 'ODM_DIRS' \
      --exclude-dir=.git . 2>/dev/null || true
} > "$OUT/odm-dirs.txt"

{
    echo "=== MEDIATEK DT MAKEFILE ==="
    cat arch/arm64/boot/dts/mediatek/Makefile 2>/dev/null || true
    echo
    echo "=== ARM64 DTS MAKEFILE ==="
    cat arch/arm64/boot/dts/Makefile 2>/dev/null || true
    echo
    echo "=== DRVGEN ==="
    cat scripts/drvgen/drvgen.mk 2>/dev/null || true
} > "$OUT/dtb-makefiles.txt"

{
    echo "=== DTBO REFERENCES ==="
    git grep -n -E 'dtbo|DTBO|OVERLAY|OVERLAYS' -- \
      ':(exclude)debug-bridge' 2>/dev/null || true
} > "$OUT/dtbo-references.txt"

{
    echo "=== OVERLAY DIRECTORIES ==="
    find device -type d -path '*/overlays*' -print 2>/dev/null || true
    echo
    echo "=== DTBO FILES IN SOURCE ==="
    find device arch setup -type f \( -name '*.dtbo' -o -name '*.dtso' \) \
      -print 2>/dev/null || true
} > "$OUT/overlay-tree.txt"

{
    echo "=== BUILD CONFIG ==="
    find . -maxdepth 4 -type f -name 'build.config*' \
      -not -path './debug-bridge/*' \
      -print 2>/dev/null | sort
    echo
    for f in $(find . -maxdepth 4 -type f -name 'build.config*' \
      -not -path './debug-bridge/*' 2>/dev/null | sort); do
        echo "===== $f ====="
        sed -n '1,260p' "$f"
    done
} > "$OUT/build-configs.txt"

{
    echo "=== BUILD.SH OVERLAY SECTION ==="
    sed -n '930,1030p' setup/kernel/build/build.sh 2>/dev/null || true
    echo
    echo "=== BUILD_KERNEL.SH ==="
    sed -n '1,180p' setup/build_kernel.sh 2>/dev/null || true
} > "$OUT/build-scripts.txt"

{
    echo "=== CURRENT OUTPUT FILES ==="
    find . -type f \
      \( -name 'Image.gz' -o -name '*.dtb' -o -name '*.dtbo' -o -name '.config' \) \
      -not -path './debug-bridge/*' \
      -printf '%p %s bytes\n' 2>/dev/null | sort
} > "$OUT/output-files.txt"

echo "Collector finished."
echo "Report: $OUT"
