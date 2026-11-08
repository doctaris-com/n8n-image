# n8n for doctaris.com: official n8n image plus ffmpeg (Bunny reel workflows),
# ssh/curl (fetching a backup for restore) and a restore step before n8n starts.
ARG N8N_VERSION=2.46.6
FROM n8nio/n8n:${N8N_VERSION}

USER root
# The n8n image ships without apk; borrow it from Alpine to install packages.
COPY --from=alpine:3.24 /sbin/apk /sbin/apk
COPY --from=alpine:3.24 /usr/lib/libapk.so* /usr/lib/
RUN apk add --no-cache ffmpeg openssh-client curl flock \
 && ffmpeg -version | head -1

COPY restore-entrypoint.sh /restore-entrypoint.sh
RUN chmod 755 /restore-entrypoint.sh

USER node
ENTRYPOINT ["tini", "--", "/restore-entrypoint.sh"]
