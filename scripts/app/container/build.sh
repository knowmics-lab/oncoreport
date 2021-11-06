#!/usr/bin/env bash

[ -f "./databases/Disease.txt" ] && mv ./databases/Disease.txt ./databases/Disease_old.txt
CURR_DIR="$(pwd)"
cd "../icd_parser/" || exit 1
bash process_icd11.bash
if [ -f "icd11_diseases.txt" ]; then
  mv icd11_diseases.txt "$CURR_DIR/databases/Disease.txt"
else
  if [ -f "$CURR_DIR/databases/Disease_old.txt" ]; then
    if ! mv "$CURR_DIR/databases/Disease_old.txt" "$CURR_DIR/databases/Disease.txt"; then
      echo "Unable to generate ICD11 database or restore the previous database"
      exit 1
    fi
  else
    echo "Unable to generate ICD11 database or restore the previous database"
    exit 1
  fi
fi
[ -f "$CURR_DIR/databases/Disease_old.txt" ] && rm "$CURR_DIR/databases/Disease_old.txt"
cd "$CURR_DIR" || exit 1

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
echo "Enter your drugbank username:"
read -r DRUGBANK_USERNAME
echo "Enter your drugbank password:"
read -r -s DRUGBANK_PASSWORD
printf '%s\n%s\n' "$DRUGBANK_USERNAME" "$DRUGBANK_PASSWORD" >/tmp/secret_drugbank
DOCKER_BUILDKIT=1 docker build --secret id=drugbank,src=/tmp/secret_drugbank --squash -t alaimos/oncoreport:v0.0.1 . &&
  rm ws.tgz &&
  rm /tmp/secret_drugbank
