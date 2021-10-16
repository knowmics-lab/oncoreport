#!/usr/bin/env bash

## DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if [ ! -f ws.tgz ]; then
  mkdir repo || exit
  cd repo || exit
  git clone git@github.com:gretep/oncoreport.git || exit
  cd oncoreport || exit
  if [ -n "$1" ]; then
    git checkout "$1"
  fi
  tar -zcvf ../../ws.tgz ws/
  cd ../../ || exit
  rm -rf repo/ || exit
fi

[[ ! -f ws.tgz ]] && echo "Archive not built!" && exit

docker build -t alaimos/oncoreport:v0.0.1 . && rm ws.tgz
