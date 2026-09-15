#!/bin/bash

FILE="$HOME/.config/caelestia/shell.json"

if grep -q '"persistent": true' "$FILE"; then
    sed -i 's/"persistent": true/"persistent": false/' "$FILE"
else
    sed -i 's/"persistent": false/"persistent": true/' "$FILE"
fi
