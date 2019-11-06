#!/bin/bash -ex

. .ci/scripts/common/pre-upload.sh

REV_NAME="yuzu-linux-${GITDATE}-${GITREV}"
ARCHIVE_NAME="${REV_NAME}.tar.xz"
COMPRESSION_FLAGS="-cJvf"

if [ "${RELEASE_NAME}" = "mainline" ]; then
    DIR_NAME="${REV_NAME}_${RELEASE_NAME}"
else
    DIR_NAME="${REV_NAME}"
fi

mkdir "$DIR_NAME"

cp build/bin/yuzu-cmd "$DIR_NAME"
cp build/bin/yuzu "$DIR_NAME"

. .ci/scripts/common/post-upload.sh
