#!/bin/bash -ex
mkdir -p "$HOME/.ccache"
docker run --env-file .travis/common/travis-ci.env -v $(pwd):/citra -v "$HOME/.ccache":/root/.ccache liushuyu/osxcross:qt5 /bin/bash -ex /citra/.travis/linux-osxcross/docker.sh
