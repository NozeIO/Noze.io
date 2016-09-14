#!/bin/bash

# export PATH="${SWIFTENV_ROOT}/bin:${SWIFTENV_ROOT}/shims:$PATH"

# Install Swift

wget "${SWIFT_SNAPSHOT_NAME}"

TARBALL="`ls swift-*.tar.gz`"
echo "Tarball: $TARBALL"

tar zx --strip 1 --file=$TARBALL
pwd

export PATH="$PWD/usr/bin:$PATH"
which swift
find $PWD/usr/

if [ `which swift` ]; then
    echo "Installed Swift: `which swift`"
else
    echo "Failed to install Swift?"
    exit 42
fi
swift --version


# Environment

TT_SWIFT_BINARY=`which swift`

echo "${TT_SWIFT_BINARY}"
