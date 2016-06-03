#!/bin/sh

HAS_PACKAGE="x`which swift-package`"

if test "${HAS_PACKAGE}" = "x"; then
  for i in `ls`; do
    if test -d "$i"; then
      cd $i; swift build --update; cd ..
    fi
  done
else
  for i in `ls`; do
    if test -d "$i"; then
      cd $i; swift package update; cd ..
    fi
  done
fi

    
