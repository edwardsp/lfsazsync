#!/bin/bash

#docker run -it --entrypoint /bin/bash -v $(pwd):/rbh -w /rbh rbh-almalinux-87

git clone https://github.com/cea-hpc/robinhood.git
cd robinhood
git checkout 3.1.5
git apply ../robinhood.patch
autoreconf --install
./configure --prefix=/opt/robinhood --enable-lustre --enable-jemalloc
make -j16
make install
orig_dir=$(pwd)
cd /opt
tar zcvf $orig_dir/robinhood.tar.gz robinhood
cd $orig_dir