#!/bin/bash

if [[ "$TRAVIS_OS_NAME" == "Linux" ]]; then
  # GCD prerequisites
    sudo apt-get install -y \
       clang make git libicu52 \
       autoconf libtool pkg-config \
       libblocksruntime-dev \
       libkqueue-dev \
       libpthread-workqueue-dev \
       systemtap-sdt-dev \
       libbsd-dev libbsd0 libbsd0-dbg
fi
