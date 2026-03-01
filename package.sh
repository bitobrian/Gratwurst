#!/usr/bin/env bash
# package.sh <version> [source-dir]
# Stages addon files into .releases/<addon>/, substitutes @project-version@,
# and zips to .releases/<addon>-release-v<version>.zip
set -euo pipefail

VERSION="${1:-}"
SOURCE_DIR="${2:-.}"

if [ -z "$VERSION" ]; then
    echo "Usage: $0 <version> [source-dir]" >&2
    exit 1
fi

# Discover .toc
cd "$SOURCE_DIR"
toc_files=(*.toc)
if [ "${#toc_files[@]}" -ne 1 ]; then
    echo "Expected exactly one .toc file, found ${#toc_files[@]}" >&2
    exit 1
fi
ADDON_NAME=$(basename "${toc_files[0]}" .toc)
TAG_NAME="${ADDON_NAME}-release-v${VERSION}"
STAGE_DIR=".releases/${ADDON_NAME}"
ZIP_PATH=".releases/${TAG_NAME}.zip"

echo "Addon:   ${ADDON_NAME}"
echo "Version: ${VERSION}"
echo "Output:  ${ZIP_PATH}"

# Stage
rm -rf "${STAGE_DIR}"
mkdir -p "${STAGE_DIR}"
cp "${ADDON_NAME}.lua" "${STAGE_DIR}/"
cp "${ADDON_NAME}.toc" "${STAGE_DIR}/"
cp "${ADDON_NAME}.xml" "${STAGE_DIR}/"
if [ -d "media" ]; then
    cp -R media "${STAGE_DIR}/"
fi

# Substitute version tokens
sed -i "s|@project-version@|${VERSION}|g" "${STAGE_DIR}/${ADDON_NAME}.toc"
sed -i "s|@project-version@|${VERSION}|g" "${STAGE_DIR}/${ADDON_NAME}.lua"
sed -i "s|@project-version@|${VERSION}|g" "${STAGE_DIR}/${ADDON_NAME}.xml"

# Zip
rm -f "${ZIP_PATH}"
(cd .releases && zip -9 -r "${TAG_NAME}.zip" "${ADDON_NAME}")

echo "Done: ${ZIP_PATH}"
