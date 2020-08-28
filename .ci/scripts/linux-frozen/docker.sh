#!/bin/bash -ex

ccache -s

mkdir -p build && cd build
cmake .. -G Ninja -DCMAKE_BUILD_TYPE=Debug -DCMAKE_C_COMPILER=/usr/lib/ccache/gcc -DCMAKE_CXX_COMPILER=/usr/lib/ccache/g++
ninja

ctest -VV -C Release
