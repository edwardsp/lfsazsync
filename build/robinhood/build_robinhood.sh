#!/bin/bash

#docker run -it --entrypoint /bin/bash -v $(pwd):/rbh -w /rbh rbh-almalinux-87

scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $scriptDir
pwd

git clone https://github.com/cea-hpc/robinhood.git
cd robinhood
git checkout 3.1.5
git apply ../robinhood.patch
autoreconf --install
./configure --prefix=/opt/robinhood --enable-lustre --enable-jemalloc
make -j16
make install
mkdir -p /opt/robinhood/etc/robinhood.d/includes
cp doc/templates/includes/lhsm.inc /opt/robinhood/etc/robinhood.d/includes
cd /opt
tar zcvf $scriptDir/robinhood.tgz robinhood
