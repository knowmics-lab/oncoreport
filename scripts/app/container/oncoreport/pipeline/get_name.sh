#!/bin/bash

X=$(basename "$1")
NAME=$(basename "${X%.*}")
if [ "${X: -3}" == ".gz" ]; then
  NAME=$(basename "${NAME%.*}")
fi

echo "$NAME"