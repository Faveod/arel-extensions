#!/bin/sh -e
# vim: set et sw=2 ts=2:
if [ -z "$ORACLE_COOKIE" ]; then  # -z variable vide. on veut savoir si la variable $ORACLE_COOKIE (contient:ORACLE_COOKIE=sqldev) est vide, si elle l'est echo...
	echo "Missing ORACLE_COOKIE environment variable!"
	 exit 1
fi 
if [ -z "$ORACLE_FILE" ]; then # -z variable vide. on veut savoir si la variable $ORACLE_FILE (contient:ORACLE_FILE=oracle11g/xe/oracle-xe-11.2.0-1.0.x86_64.rpm.zip) est vide, si elle l'est echo...
	echo "Missing ORACLE_FILE environment variable!"
	 exit 1 
fi

ORACLE_DOWNLOAD_FILE="$(basename "$ORACLE_FILE")" #basename permet de récuperer l'enssemble du chemin sauf "le dernier élément" ORACLE_FILE=oracle11g/xe"/oracle-xe-11.2.0-1.0.x86_64.rpm.zip"

if [ -z "$ORACLE_DOWNLOAD_DIR" ];#verifie si la variable d'environemment est vide
 then # defini le début du bloque d'instruction
	mkdir -p "$ORACLE_DOWNLOAD_DIR" #Si les répertoires parent n'existent pas, cette commande les crée.
	ORACLE_DOWNLOAD_FILE="$(readlink -f "$ORACLE_DOWNLOAD_DIR")/$ORACLE_DOWNLOAD_FILE"
fi 

if [ "${*#*--unless-exists}" != "$*" ] && [ -f "$ORACLE_DOWNLOAD_FILE" ]; then # -f permet de savoir si le fichier est normal
	 exit 0
fi

cd "$(dirname "$(readlink -f "$0")")" #dirname envoie le nom du répertoire contenant le fichier/répertoire placé en paramètre. readlink -f Readlink imprime la valeur d'un lien symbolique ou d'un nom de fichier

npm install bluebird node-phantom-simple

export ORACLE_DOWNLOAD_FILE #sert a mettre les variable dans la variable d'environment
export COOKIES='cookies.txt'
export USER_AGENT='Mozilla/5.0'

echo > "$COOKIES"
chmod 600 "$COOKIES" #permet de modifier les droit d'un fichier pour différents utilisateur: le propriétaire peut le lire et l'écrire

exec node download.js
