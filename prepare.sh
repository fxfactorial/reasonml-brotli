#! bin/sh

set -eou

git clone https://github.com/bagder/libbrotli
cd libbrotli
./autogen.sh
./configure
make
make install
cd ..
rm -rf libbrotli
