#!/bin/bash -ex

. .travis/common/pre-upload.sh

REV_NAME="citra-windows-mingw-${GITDATE}-${GITREV}"
ARCHIVE_NAME="${REV_NAME}.zip"
USE_ZIP='1'

mkdir "$REV_NAME"{,-debugsymbols}

cp -rv build/bin/Release/* "$REV_NAME"
mv "$REV_NAME"/*.pdb "$REV_NAME-debugsymbols"

. .travis/common/post-upload.sh

# debug symbols
7z a "$REV_NAME-debugsymbols.7z" "$REV_NAME-debugsymbols"
mv "$REV_NAME-debugsymbols.7z" "${BUILD_ARTIFACTSTAGINGDIRECTORY}/artifacts/"
