#!/bin/bash

set -ex

sudo curl -L https://sqlite.org/contrib/download/extension-functions.c?get=25 -o /tmp/extension-functions.c
sudo gcc -fPIC -lm -shared /tmp/extension-functions.c -o /usr/lib/sqlite3/extension-functions.so