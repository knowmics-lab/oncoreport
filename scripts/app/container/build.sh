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
if [ ! -f drugbank.xml ]; then
  echo "Enter your drugbank username:"
  read -r USERNAME
  echo "Enter your drugbank password:"
  read -r -s PASSWORD
  curl -Lf -o drugbank.zip -u "$USERNAME:$PASSWORD" https://go.drugbank.com/releases/5-1-8/downloads/all-full-database
  unzip drugbank.zip
  mv "full database.xml" drugbank.xml
  rm drugbank.zip
fi
[[ ! -f drugbank.xml ]] && echo "Unable to download drugbank.xml" && exit

docker build -t alaimos/oncoreport:v0.0.1 . && rm ws.tgz && rm drugbank.xml
