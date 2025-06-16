#!/bin/bash

CURRENT_DIR=$( dirname "$(readlink -f "$0")" )
OFFLINE_FILES_DIR_NAME="offline-files"
OFFLINE_FILES_DIR="${CURRENT_DIR}/${OFFLINE_FILES_DIR_NAME}"
OFFLINE_FILES_ARCHIVE="${CURRENT_DIR}/offline-files.tar.gz"
FILES_LIST=${FILES_LIST:-"${CURRENT_DIR}/temp/files.list"}
NGINX_PORT=8080

# run nginx container server
if command -v nerdctl 1>/dev/null 2>&1; then
    runtime="nerdctl"
elif command -v podman 1>/dev/null 2>&1; then
    runtime="podman"
elif command -v docker 1>/dev/null 2>&1; then
    runtime="docker"
else
    echo "No supported container runtime found"
    exit 1
fi

sudo "${runtime}" container inspect nginx >/dev/null 2>&1
if [ $? -ne 0 ]; then
    sudo "${runtime}" run \
        --restart=always -d -p ${NGINX_PORT}:80 \
        --volume "${OFFLINE_FILES_DIR}":/usr/share/nginx/html/download \
        --volume "${CURRENT_DIR}"/nginx.conf:/etc/nginx/nginx.conf \
        --name nginx nginx:alpine
fi
