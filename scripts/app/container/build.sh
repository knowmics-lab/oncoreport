#!/usr/bin/env bash

mkdir repo || exit
cd repo || exit
git clone https://github.com/gretep/oncoreport.git
cd oncoreport || exit
tar -zcvf ../../ws.tgz ws/
cd ../../ || exit
rm -rf repo/ || exit

docker build -t alaimos/oncoreport:v0.0.1 .

rm ws.tgz