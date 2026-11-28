#!/usr/bin/env bash
# Create the bind sources as the host user before Docker mounts them.
set -eu
mkdir -p "${WS_PATH:?}/isaac-sim"/{kit/{cache,data,logs},ov/cache,pip,nvidia/{glcache,computecache}}
