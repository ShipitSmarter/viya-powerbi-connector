#!/usr/bin/env bash
#
# Builds the Viya Power BI connector (.mez file).
# A .mez is a ZIP containing the .pq, resources.resx, and icon PNGs.
#
# Usage: ./build.sh
# Output: bin/Viya.mez
#
# Requirements: python3 (for cross-platform ZIP creation)
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONNECTOR_NAME="Viya"
OUTPUT_DIR="${SCRIPT_DIR}/bin"
MEZ_PATH="${OUTPUT_DIR}/${CONNECTOR_NAME}.mez"

mkdir -p "${OUTPUT_DIR}"

python3 -c "
import zipfile, glob, os, sys

connector_dir = '${SCRIPT_DIR}'
mez_path = '${MEZ_PATH}'

# Files to include in the .mez (flat, no subdirectories)
files = []
files.append(os.path.join(connector_dir, 'src', '${CONNECTOR_NAME}.pq'))
files.append(os.path.join(connector_dir, 'src', 'resources.resx'))
files.extend(sorted(glob.glob(os.path.join(connector_dir, 'src', '*.png'))))

# Verify required files exist
for f in files[:2]:
    if not os.path.exists(f):
        print(f'Error: required file not found: {f}', file=sys.stderr)
        sys.exit(1)

with zipfile.ZipFile(mez_path, 'w', zipfile.ZIP_DEFLATED) as zf:
    for filepath in files:
        zf.write(filepath, os.path.basename(filepath))

print(f'Built: {mez_path}')
print(f'Contents:')
with zipfile.ZipFile(mez_path, 'r') as zf:
    for info in zf.infolist():
        print(f'  {info.filename} ({info.file_size} bytes)')
"
