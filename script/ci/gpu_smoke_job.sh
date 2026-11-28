#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/../.."
# The generated Compose service for the devel-test stage is named test.
# The GPU runner has no just; call the wrapper that `just docker build` runs.
./script/build.sh test
image="$(docker compose --env-file .env.generated config --images test)"
script/ci/image_smoke.sh "${image}"
