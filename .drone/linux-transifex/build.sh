#!/bin/bash -e

if [[ "x$DRONE_BRANCH" == 'xmaster' && "x$DRONE_PULL_REQUEST" == 'x' ]]; then
  echo 'Skipped Transifex uploading as required'
  exit 0
fi

# Setup RC file for tx
echo $'[https://www.transifex.com]\nhostname = https://www.transifex.com\nusername = api\npassword = '"$TRANSIFEX_API_TOKEN"$'\n' > ~/.transifexrc

set -x
echo -e "\e[1m\e[33mBuild tools information:\e[0m"
cmake --version
gcc -v
tx --version

cd /citra
mkdir build && cd build
cmake .. -DENABLE_QT_TRANSLATION=ON -DGENERATE_QT_TRANSLATION=ON -DCMAKE_BUILD_TYPE=Release -DENABLE_SDL2=OFF
make translation
cd ..

cd dist/languages
tx push -s
