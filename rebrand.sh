#!/bin/bash
set -euo pipefail

echo "🔍 Scanning for 'kdx'..."
grep -ril "kdx" . --exclude-dir=.git --exclude-dir=release --exclude-dir=work | wc -l

echo "📦 Backup..."
tar -czf ~/knightdragonx-backup-$(date +%Y%m%d-%H%M%S).tar.gz --exclude='.git' --exclude='release' --exclude='work' .

echo "🔧 Replacing..."
find . -type f \
    -not -path "./.git/*" \
    -not -path "./release/*" \
    -not -path "./work/*" \
    -exec sed -i \
        -e 's/kdx/kdx/g' \
        -e 's/KDX/KDX/g' \
        -e 's/KDX/KDX/g' \
    {} +

echo "📝 Renaming files..."
find . -depth -name "*kdx*" \
    -not -path "./.git/*" \
    -not -path "./release/*" \
    -not -path "./work/*" \
    -exec bash -c 'mv "$1" "${1//kdx/kdx}"' _ {} \;

echo "✅ Done!"