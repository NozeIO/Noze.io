#!/bin/bash

# export PATH="${SWIFTENV_ROOT}/bin:${SWIFTENV_ROOT}/shims:$PATH"

# Install Swift

wget "${SWIFT_SNAPSHOT_NAME}"

TARBALL="`ls swift-*.tar.gz`"
echo "Tarball: $TARBALL"
ls -la

tar zx --strip 1 --file=$TARBALL
ls -la

export PATH="$HOME/usr/bin:$PATH"

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
