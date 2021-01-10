#!/usr/bin/env bash

## DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

mkdir repo || exit
cd repo || exit
git clone https://github.com/gretep/oncoreport.git
cd oncoreport || exit
tar -zcvf ../../ws.tgz ws/
cd ../../ || exit
rm -rf repo/ || exit

[[ ! -f ws.tgz ]] && echo "Archive not built!" && exit

docker build -t alaimos/oncoreport:v0.0.1 .

rm ws.tgz