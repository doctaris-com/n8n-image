#!/bin/sh
# 1. Waits until no other n8n container uses the data folder (lock file), so two containers never share
#    the SQLite database. RunCloud/Swarm starts the new container before stopping the old one; the
#    stack's readiness health check must be OFF, otherwise the new container is never marked running
#    and the old one is never stopped.
# 2. Restores a backup before n8n starts: put a tar.gz of the n8n data folder at
#    /home/node/.n8n/restore.tgz and restart the container. The current database and key are moved to
#    .pre-restore/<timestamp>/, the archive is deleted afterwards (it contains the encryption key and
#    all credentials).
set -e
DATA=/home/node/.n8n
LOCK="$DATA/.instance.lock"

exec 9>>"$LOCK"
if ! flock -n 9; then
  echo "lock: another n8n container still uses $DATA, waiting for it to stop"
  flock 9
fi
echo "lock: acquired"

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

# fd 9 stays open in n8n, so the lock is held until n8n exits.
exec /docker-entrypoint.sh "$@"
