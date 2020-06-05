#!/usr/bin/env bash
# Add mirror of zabbix repo to apt. Run in container with no internet connection.
# Author: Jan Polák
set -euo pipefail

BASEDIR=$(dirname "$0")
printf "%s\n" "$BASEDIR"

printf "%s\n" "backup old sources list"
mv /etc/apt/sources.list /etc/apt/bck_sources.list

printf "%s\n" "copy new sources list"
cp $BASEDIR/sources.list /etc/apt/sources.list

printf "%s\n" "copy zabbix repo key"
cp $BASEDIR/zabbix-official-repo.gpg /etc/apt/trusted.gpg.d/zabbix-official-repo.gpg

printf "%s\n" "delete old zabbix repo from sources.list.d"
rm /etc/apt/sources.list.d/zabbix.list

printf "%s\n" "run apt update"
apt update
