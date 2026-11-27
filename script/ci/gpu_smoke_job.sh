#!/usr/bin/env bash
# gpu_smoke_job.sh -- build the adapter image and run the container smoke on
# the self-hosted GPU runner (called through the org reusable workflow).
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${repo_root}"

image="ycpss91255/cc-lab-base:ci-${GITHUB_RUN_ID:?}-${GITHUB_RUN_ATTEMPT:?}"
trap 'docker rmi "${image}" >/dev/null 2>&1 || true' EXIT

docker build --target lab-base -t "${image}" .
./test/smoke/image_smoke.sh "${image}"
