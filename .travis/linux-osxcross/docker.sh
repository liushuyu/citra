#!/bin/bash -ex

cd /citra

export MACOSX_DEPLOYMENT_TARGET=10.13
mkdir build && cd build
x86_64-apple-darwin18-cmake .. -DCMAKE_OSX_ARCHITECTURES="x86_64;x86_64h" -DCMAKE_BUILD_TYPE=Release -DENABLE_QT_TRANSLATION=ON -DCITRA_ENABLE_COMPATIBILITY_REPORTING=${ENABLE_COMPATIBILITY_REPORTING:-"OFF"} -DENABLE_COMPATIBILITY_LIST_DOWNLOAD=ON -DUSE_DISCORD_PRESENCE=ON -DUSE_CCACHE=ON -DENABLE_FFMPEG=ON
make -j4

echo "Tests skipped"
# ctest -VV -C Release
ccache -s

# prepare the package
function patch_ffmpeg_path() {
  LIBS=$(x86_64-apple-darwin18-otool -L "$1" | perl -ne '/(\@loader_path\/libav.*dylib)/ && print "$1\n"' | sort -u)
  for i in ${LIBS}; do
    x86_64-apple-darwin18-install_name_tool -change "$i" "${i/@loader_path/@rpath}" "$1"
  done
}

echo 'Preparing binaries...'
cd ..
mkdir package

cp build/bin/citra 'package'
cp -r build/bin/citra-qt.app 'package'
cp build/bin/citra-room 'package'

export MP_DIR='/opt/osxcross/macports/pkgs/opt/local/'
echo "Deploying dependencies..."
patch_ffmpeg_path 'package/citra'
patch_ffmpeg_path 'package/citra-qt.app/Contents/MacOS/citra-qt'
macdeployqt "package/citra-qt.app" -executable=package/citra -executable=package/citra-room
# ffmpeg binaries from Zeranoe contains "@loader_path" which make macdeployqt think the binary
# has no dependencies
cp -rv "${MP_DIR}"/lib/{libswresample.3,libswscale.5}.dylib 'package/citra-qt.app/Contents/Frameworks/'
