#!/bin/bash -ex

# Copy documentation
cp license.txt "$REV_NAME"
cp README.md "$REV_NAME"

# Copy cross-platform scripting support
cp -r dist/scripting "$REV_NAME"

tar $COMPRESSION_FLAGS "$ARCHIVE_NAME" "$REV_NAME"

# Find out what release we are building
if [ -z $TRAVIS_TAG ]; then
    RELEASE_NAME=head
else
    RELEASE_NAME=$(echo $TRAVIS_TAG | cut -d- -f1)
    if [ "$NAME" = "MinGW build" ]; then
        RELEASE_NAME="${RELEASE_NAME}-mingw"
    fi
fi

mv "$REV_NAME" $RELEASE_NAME

7z a "$REV_NAME.7z" $RELEASE_NAME

# move the compiled archive into the artifacts directory to be uploaded by azure pipelines
# BUILD_ARTIFACTSTAGINGDIRECTORY is defined by az-pipeline agent
mv "$ARCHIVE_NAME" "${BUILD_ARTIFACTSTAGINGDIRECTORY}/artifacts/"
mv "$REV_NAME.7z" "${BUILD_ARTIFACTSTAGINGDIRECTORY}/artifacts/"
