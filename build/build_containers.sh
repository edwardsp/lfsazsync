#!/bin/bash

# prefix for docker build
prefix=${1:-""}

for dir in lemur robinhood; do
    for os in almalinux87 ubuntu2004; do
        docker build -t ${prefix}lfsazsync-$dir-$os -f $dir/Dockerfile.$os $dir
    done
done
