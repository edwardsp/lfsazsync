#!/bin/bash

#docker run -it --entrypoint /bin/bash -v $(pwd):/lemur -w /lemur lemur-almalinux-87

scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $scriptDir
pwd

git clone https://github.com/edwardsp/lemur.git
cd lemur
git checkout lfsazsync

go mod download github.com/edwardsp/go-lustre
./build_plugin.sh
mv dist lemur
tar zcvf $scriptDir/lemur.tgz lemur
