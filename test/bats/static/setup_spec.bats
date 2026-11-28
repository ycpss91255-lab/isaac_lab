#!/usr/bin/env bats

setup() {
  cd "${BATS_TEST_DIRNAME}/../../.." || return 1
  config="$BATS_TEST_TMPDIR/setup.json"
  yq -p toml -o json '.' setup.toml > "$config"
}

@test "setup selects an Isaac Lab image name and supplies the base build arguments" {
  jq -e '.image.rules[0].rule | test("^string:.*(lab|Lab)")' "$config"
  local arg
  for arg in APT_MIRROR_UBUNTU APT_MIRROR_DEBIAN TZ; do
    jq -e --arg key "$arg" 'any(.build.args[]; .key == $key and (.value | length > 0))' "$config"
  done
}

@test "setup uses host networking and auto GPU selection with stage-specific overrides" {
  jq -e '.network.mode == "host" and .deploy.gpu_mode == "auto"' "$config"
  jq -e '.["stage:devel-test"]["deploy.gpu_mode"] == "force"' "$config"
  jq -e '.["stage:headless"]["gui.mode"] == "off"' "$config"
}

@test "setup binds the workspace and persistent Isaac Sim caches" {
  # The base wrapper expands these placeholders when it renders Compose.
  # shellcheck disable=SC2016
  local work='/home/${USER_NAME}' caches='${WS_PATH}/isaac-sim'
  jq -e --arg target "$work/work" 'any(.volumes[]; .source == "${WS_PATH}" and .target == $target)' "$config"
  local mount
  for mount in 'kit/cache /isaac-sim/kit/cache' 'kit/data /isaac-sim/kit/data' \
    'kit/logs /isaac-sim/kit/logs' "ov/cache $work/.cache/ov" \
    "pip $work/.cache/pip" "nvidia/glcache $work/.cache/nvidia/GLCache" \
    "nvidia/computecache $work/.nv/ComputeCache"; do
    jq -e --arg src "$caches/${mount%% *}" --arg dst "${mount#* }" \
      'any(.volumes[]; .source == $src and .target == $dst)' "$config"
  done
}

@test "active setup settings omit ROS and streaming integrations" {
  run grep -Ei 'stage:(stream|producer)|livestream|webrtc|streaming|ros2|ros_domain_id|ros_distro|/opt/ros/' "$config"
  [ "$status" -eq 1 ]
}
