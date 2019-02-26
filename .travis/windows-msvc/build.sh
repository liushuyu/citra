#!/bin/bash -ex

# TODO(liushuyu): msvc can also utilize certain sort of cache
mkdir build && cd build
cmake -G "Visual Studio 15 2017 Win64" -DCITRA_USE_BUNDLED_QT=1 -DCITRA_USE_BUNDLED_SDL2=1 -DCITRA_ENABLE_COMPATIBILITY_REPORTING=${ENABLE_COMPATIBILITY_REPORTING:-"OFF"} -DENABLE_COMPATIBILITY_LIST_DOWNLOAD=ON -DUSE_DISCORD_PRESENCE=ON  -DENABLE_MF=ON ..
cmake --build . --config Release -- -m

ctest -VV -C Release
