#!/bin/bash -ex

RELEASE_NAME="${RELEASE_NAME:-head}"

# Copy documentation
cp -nv license.txt "$DIR_NAME"
cp -nv README.md "$DIR_NAME"

tar -cJvf "${REV_NAME}-source.tar.xz" src externals CMakeLists.txt README.md license.txt
cp -nv "${REV_NAME}-source.tar.xz" "$DIR_NAME"

tar $COMPRESSION_FLAGS "$ARCHIVE_NAME" "$DIR_NAME"

mv -v "$DIR_NAME" $RELEASE_NAME
mv -v "${REV_NAME}-source.tar.xz" $RELEASE_NAME

7z a "$REV_NAME.7z" $RELEASE_NAME

# move the compiled archive into the artifacts directory to be uploaded by travis releases
mv -v "$ARCHIVE_NAME" artifacts/
mv -v "$REV_NAME.7z" artifacts/
