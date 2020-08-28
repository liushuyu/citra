#!/bin/bash -ex

RELEASE_NAME="${RELEASE_NAME:-head}"
# Copy documentation
cp -v license.txt "$REV_NAME"
cp -v README.md "$REV_NAME"

# Copy cross-platform scripting support
cp -rv dist/scripting "$REV_NAME"

tar $COMPRESSION_FLAGS "$ARCHIVE_NAME" "$REV_NAME"

mv -v "$REV_NAME" $RELEASE_NAME

7z a "$REV_NAME.7z" $RELEASE_NAME

# move the compiled archive into the artifacts directory to be uploaded by travis releases
mv -v "$ARCHIVE_NAME" artifacts/
mv -v "$REV_NAME.7z" artifacts/
