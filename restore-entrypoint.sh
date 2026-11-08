#!/bin/sh
# Restores a backup before n8n starts.
# Put a tar.gz of the n8n data folder at /home/node/.n8n/restore.tgz and restart the container.
# The current database and key are moved to .pre-restore/<timestamp>/, the archive is deleted afterwards
# (it contains the encryption key and all credentials).
set -e
DATA=/home/node/.n8n

if [ -f "$DATA/restore.tgz" ]; then
  STAMP=$(date +%Y%m%d-%H%M%S)
  echo "restore: found $DATA/restore.tgz, moving current data to .pre-restore/$STAMP"
  mkdir -p "$DATA/.pre-restore/$STAMP"
  for f in database.sqlite database.sqlite-wal database.sqlite-shm config; do
    if [ -e "$DATA/$f" ]; then mv "$DATA/$f" "$DATA/.pre-restore/$STAMP/"; fi
  done
  tar xzf "$DATA/restore.tgz" -C "$DATA"
  rm -f "$DATA/restore.tgz"
  echo "restore: done"
fi

exec /docker-entrypoint.sh "$@"
