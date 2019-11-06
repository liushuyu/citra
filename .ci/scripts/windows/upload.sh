#!/bin/bash -ex

. .ci/scripts/common/pre-upload.sh

REV_NAME="yuzu-windows-mingw-${GITDATE}-${GITREV}"
ARCHIVE_NAME="${REV_NAME}.tar.gz"
COMPRESSION_FLAGS="-czvf"

if [ "${RELEASE_NAME}" = "mainline" ]; then
    DIR_NAME="${REV_NAME}_${RELEASE_NAME}"
else
    DIR_NAME="${REV_NAME}"
fi

mkdir "$DIR_NAME"
# get around the permission issues
cp -r package/* "$DIR_NAME"

. .ci/scripts/common/post-upload.sh
