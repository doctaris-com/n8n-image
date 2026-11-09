#!/bin/sh
# 1. Waits until no other n8n container uses the data folder (lock file), so two containers never share
#    the SQLite database. RunCloud/Swarm starts the new container before stopping the old one and
#    waits for the new one's readiness check; while waiting for the lock, a placeholder answers
#    that check on port 5678 so the old container gets stopped.
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
  # Swarm (start-first) only stops the old container once this one passes its readiness check
  # (RunCloud's check falls back to an HTTP request on port 5678). Answer it with a placeholder
  # HTTP 200 until the lock is free.
  node -e "require('http').createServer((q, r) => { r.writeHead(200, {'Content-Type': 'text/plain', 'Connection': 'close'}); r.end('n8n is starting\n'); }).listen(5678)" &
  PLACEHOLDER=$!
  flock 9
  kill "$PLACEHOLDER" 2>/dev/null || true
  wait "$PLACEHOLDER" 2>/dev/null || true
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
