#!/bin/bash

# URLS

TT_SWIFTENV_URL="https://github.com/kylef/swiftenv.git"
TT_GCD_URL="https://github.com/apple/swift-corelibs-libdispatch.git"

#TT_GCD_SWIFT3_BRANCH=experimental/foundation
#TT_GCD_SWIFT22_1404_HASH=65330e06d9bbf75a4c6ddc349548536746845059
TT_GCD_SWIFT3_BRANCH=master
TT_GCD_SWIFT22_1404_HASH=master

# swiftenv

git clone --depth 1 ${TT_SWIFTENV_URL} ~/.swiftenv

export SWIFTENV_ROOT="$HOME/.swiftenv"
export PATH="${SWIFTENV_ROOT}/bin:${SWIFTENV_ROOT}/shims:$PATH"


# Install Swift

swiftenv install ${SWIFT_SNAPSHOT_NAME}

if [ `which swift` ]; then
    echo "Installed Swift: `which swift`"
else
    echo "Failed to install Swift?"
    exit 42
fi
swift --version


# Environment

TT_SWIFT_BINARY=`swiftenv which swift`
TT_SNAP_DIR=`echo $TT_SWIFT_BINARY | sed "s|/usr/bin/swift||g"`


# Install GCD

if [[ "$TRAVIS_OS_NAME" == "Linux" ]]; then
  IS_SWIFT_22="`swift --version|grep 2.2|wc -l|sed s/1/yes/|sed s/0/no/`"
  echo "${IS_SWIFT_22}"
  
  #GCD_DIRNAME="gcd-${SWIFT_SNAPSHOT_NAME}"
  GCD_DIRNAME=gcd
  
  git clone --recursive ${TT_GCD_URL} ${GCD_DIRNAME}
  cd ${GCD_DIRNAME}

  if [[ $IS_SWIFT_22 = "no" ]]; then
    git checkout ${TT_GCD_SWIFT3_BRANCH}
  else
    git checkout ${TT_GCD_SWIFT22_1404_HASH}
  fi
  
  mkdir ~/swift-not-so-much
  ln -s ${TT_SNAP_DIR} ~/swift-not-so-much/latest
  
  export CC=clang
  ./autogen.sh
  ./configure --with-swift-toolchain=${TT_SNAP_DIR}/usr --prefix=${TT_SNAP_DIR}/usr

  echo "---"
  
  if [[ $IS_SWIFT_22 = "no" ]]; then
    echo "Copying patched dispatch.h"
    cp ${TRAVIS_BUILD_DIR}/xcconfig/dispatch.h-patched-swift3 dispatch/dispatch.h
    ls dispatch
  else
    echo "NOT copying dispatch.h"
  fi
  
  echo "---"
  
  #cd src && dtrace -h -s provider.d && cd ..
  cp ${TRAVIS_BUILD_DIR}/xcconfig/trusty-provider.d src
  
  make all
  make install
  
  find ~ -name "*dispatch*"
fi

if [[ "$TRAVIS_OS_NAME" == "osx" ]]; then
  echo ${TT_SWIFT_BINARY}
fi
