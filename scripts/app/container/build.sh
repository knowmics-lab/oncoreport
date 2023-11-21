#!/usr/bin/env bash

[ -f "./databases/Disease.txt" ] && rm ./databases/Disease.txt

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

if [ ! -d "./databases/hg19" ] || [ ! -d "./databases/hg38" ]; then
  rm -rf ./databases/hg19
  rm -rf ./databases/hg38
  bash ./scripts/build_dbnsfp.sh ./databases/
fi

[[ ! -d "./databases/hg19/dbNSFP" ]] && echo "hg19 dbNSFP database not built!" && exit
[[ ! -d "./databases/hg38/dbNSFP" ]] && echo "hg38 dbNSFP database not built!" && exit

echo "Enter your drugbank username:"
read -r DRUGBANK_USERNAME
echo "Enter your drugbank password:"
read -r -s DRUGBANK_PASSWORD
printf '%s\n%s\n' "$DRUGBANK_USERNAME" "$DRUGBANK_PASSWORD" >/tmp/secret_drugbank
DOCKER_BUILDKIT=1 docker build --no-cache --secret id=drugbank,src=/tmp/secret_drugbank --squash -t alaimos/oncoreport:v0.0.1 . &&
  rm ws.tgz &&
  rm /tmp/secret_drugbank
