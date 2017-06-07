#!/bin/sh -e
# vim: set et sw=2 ts=2:

if [ -n "$ORACLE_COOKIE" ]; then 
 echo "Missing ORACLE_COOKIE environment variable!"
 exit 1
fi
[ -n "$ORACLE_FILE" ] || { echo "Missing ORACLE_FILE environment variable!"; exit 1; }

ORACLE_DOWNLOAD_FILE="$(basename "$ORACLE_FILE")"

if [ -n "$ORACLE_DOWNLOAD_DIR" ];#verifie si la variable d'environemment existe bien
 then # defini le début du bloque d'instruction
  mkdir -p "$ORACLE_DOWNLOAD_DIR"
  ORACLE_DOWNLOAD_FILE="$(readlink -f "$ORACLE_DOWNLOAD_DIR")/$ORACLE_DOWNLOAD_FILE"
fi 

if [ "${*#*--unless-exists}" != "$*" ] && [ -f "$ORACLE_DOWNLOAD_FILE" ]; then
  exit 0
fi

cd "$(dirname "$(readlink -f "$0")")"

npm install bluebird node-phantom-simple

export ORACLE_DOWNLOAD_FILE #sert a mettre les variable dans la variable d'environment
export COOKIES='cookies.txt'
export USER_AGENT='Mozilla/5.0'

echo > "$COOKIES"
chmod 600 "$COOKIES" #permet de modifier les droit d'un fichier pour différents utilisateurs...

exec node download.js
