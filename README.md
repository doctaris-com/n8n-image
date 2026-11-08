# n8n-image

n8n for n8n.doctaris.com: the official n8n image plus ffmpeg, ssh and curl, and a restore step.
Built by GitHub Actions for amd64 and arm64 and pushed to `ghcr.io/doctaris-com/n8n-image:<n8n-version>`.

## New n8n version

Actions → "Build image" → Run workflow → enter the version (e.g. `2.47.0`).
Then set the image tag in the RunCloud stack and deploy. Never use `latest`.

## Restore a backup

1. Put a `tar.gz` of the n8n data folder (`database.sqlite`, `config`, optionally `binaryData/`) at
   `/home/node/.n8n/restore.tgz` inside the container (e.g. download it with an "Execute Command" node;
   download to `restore.tgz.part` first, then rename).
2. Restart the container. Before n8n starts, the current database and `config` move to
   `.pre-restore/<timestamp>/`, the archive is unpacked and deleted.

`config` holds the encryption key. Without the matching key all credentials are unreadable.
