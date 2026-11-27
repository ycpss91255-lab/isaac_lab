#!/usr/bin/env bash
# image_smoke.sh -- container smoke for the isaac_lab image.
#
# Usage: image_smoke.sh <image>
# Needs Docker and an NVIDIA GPU runtime. Checks, inside the image:
#   1. isaaclab.sh -p can import isaacsim and isaaclab
#   2. torch is importable and sees CUDA
#   3. the container runs as the host uid/gid (docker run --user)
#   4. exactly one passwd entry has UID 1000
# Commands passed to check expand inside the container.
# shellcheck disable=SC2016
set -euo pipefail

image="${1:?usage: image_smoke.sh <image>}"
fail=0

run_in() {
  docker run --rm --gpus all --user "$(id -u):$(id -g)" \
    -e ACCEPT_EULA=Y -e PRIVACY_CONSENT=Y \
    --entrypoint bash "${image}" -c "$1"
}

check() {
  local name="$1" cmd="$2"
  if out="$(run_in "${cmd}" 2>&1)"; then
    echo "PASS ${name}"
  else
    echo "FAIL ${name}"
    echo "${out}" | tail -20
    fail=1
  fi
}

check "import isaacsim" \
  '"${ISAACLAB_PATH}/isaaclab.sh" -p -c "import isaacsim; print(isaacsim.__file__)"'
check "import isaaclab" \
  '"${ISAACLAB_PATH}/isaaclab.sh" -p -c "import isaaclab; print(isaaclab.__file__)"'
check "torch sees CUDA" \
  '"${ISAACLAB_PATH}/isaaclab.sh" -p -c "import torch; assert torch.cuda.is_available(); print(torch.__version__)"'
check "exactly one passwd entry for UID 1000" \
  '[ "$(getent passwd | cut -d: -f3 | grep -cx 1000)" -eq 1 ] || {
    echo "Expected one entry with UID 1000. Matching passwd records follow."
    getent passwd | awk -F: "\$3 == 1000"
    exit 1
  }'

uid_out="$(run_in 'id -u; id -g' 2>&1 || true)"
if [ "${uid_out}" = "$(id -u)"$'\n'"$(id -g)" ]; then
  echo "PASS user uid/gid equals host"
else
  echo "FAIL user uid/gid equals host (got: ${uid_out})"
  fail=1
fi

exit "${fail}"
