#!/bin/bash -ex

. .travis/common/pre-upload.sh

REV_NAME="citra-windows-mingw-${GITDATE}-${GITREV}"
ARCHIVE_NAME="${REV_NAME}.zip"
USE_ZIP='1'

mkdir "$REV_NAME"

cp -rv build/bin/Release/* "$REV_NAME"
rm -rf "$REV_NAME"/*.pdb

. .travis/common/post-upload.sh
