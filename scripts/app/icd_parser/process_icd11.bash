#!/usr/bin/env bash

if ! composer install; then
  echo "Unable to install dependencies"
  exit 1
fi

echo "Starting WHO API docker container..."
docker run -p 8088:80 -e acceptLicense=true -e saveAnalytics=false --name whoapi whoicd/icd-api >/dev/null 2>&1 &

COUNTER=0
while [ -z "$(docker ps -aq -f status=running -f name=whoapi)" ]; do
  sleep 1
  ((COUNTER++))
  if ((COUNTER == 60)); then
    echo "Unable to start docker container."
    exit 1
  fi
done
COUNTER=0
while ! docker logs whoapi | grep -q "ICD-11 Container is Running"; do
  sleep 1
  ((COUNTER++))
  if ((COUNTER == 60)); then
    echo "Unable to start docker container."
    exit 1
  fi
done

[ -f "icd_to_diseases.json" ] && rm icd_to_diseases.json

echo "Preparing list of supported diseases..."
if ! php prepare_icd_to_disease.php; then
  echo "Error!"
  exit 1
fi

[ -f "icd_version.txt" ] && rm icd_version.txt
docker exec whoapi ls /tmp | grep "icd11" | cut -d '_' -f 2 | cut -d '-' -f 1,2 >icd_version.txt
if [ ! -f "icd_version.txt" ]; then
  echo "Unable to determine ICD11 version"
  exit 1
fi

echo "Downloading and parsing ICD-11 diseases..."
if ! php download_icd.php; then
  echo "Error!"
  exit 1
fi

echo "Stopping and removing WHO API docker container..."
docker stop whoapi && docker rm whoapi
echo "Done!"
