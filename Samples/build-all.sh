#!/bin/sh

UNAME=`uname -s`

BFLAGS=

if [ "x${UNAME}" = "xDarwin" ]; then
BFLAGS=
else
BFLAGS="-Xcc -fblocks -Xlinker -ldispatch"
fi

for i in `ls`; do
  if test -d "$i"; then
    cd $i
    swift build ${BFLAGS} # no parallel &
    cd ..
  fi
done

wait

