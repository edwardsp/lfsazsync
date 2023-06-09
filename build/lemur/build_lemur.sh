#!/bin/bash

#docker run -it --entrypoint /bin/bash -v $(pwd):/lemur -w /lemur lemur-almalinux-87

git clone https://github.com/edwardsp/lemur.git
cd lemur
git checkout lfsazsync

./build_plugin.sh
mv dist lemur
tar zcvf ../lemur.tar.gz lemur
