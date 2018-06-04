#!/bin/bash -ex

cd /citra

mkdir build && cd build
cmake .. -DCMAKE_TOOLCHAIN_FILE="$(pwd)/../CMakeModules/MinGWCross.cmake" -DUSE_CCACHE=ON -DCMAKE_BUILD_TYPE=Release -DENABLE_QT_TRANSLATION=ON -DCITRA_ENABLE_COMPATIBILITY_REPORTING=${ENABLE_COMPATIBILITY_REPORTING:-"OFF"} -DENABLE_COMPATIBILITY_LIST_DOWNLOAD=ON
make -j4

echo "Tests skipped"
#ctest -VV -C Release

ccache -s

echo 'Prepare binaries...'
cd ..
mkdir package

QT_PLATFORM_DLL_PATH='/usr/x86_64-w64-mingw32/lib/qt5/plugins/platforms/'
find build/ -name "citra*.exe" -exec cp {} 'package' \;

mkdir package/platforms
cp "${QT_PLATFORM_DLL_PATH}/qwindows.dll" package/platforms/
cp -r "${QT_PLATFORM_DLL_PATH}/../mediaservice/" package/


for i in package/*.exe; do
  # we need to process pdb here, however, cv2pdb
  # does not work here, so we just simply strip all the debug symbols
  x86_64-w64-mingw32-strip "${i}"
done

pip3 install pefile
python3 .travis/linux-mingw/scan_dll.py package/*.exe "package/"
