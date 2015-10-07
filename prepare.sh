#! bin/sh

git clone https://github.com/bagder/libbrotli
cd libbrotli
./autogen.sh
./configure
make
make install
