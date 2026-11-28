#!/usr/bin/env bats

setup() {
  cd "${BATS_TEST_DIRNAME}/../../.." || return 1
  # Work on active instructions, with backslash continuations joined.
  awk '/^[[:space:]]*#/ {next} sub(/\\$/, "") {printf "%s", $0; next} {print}' Dockerfile > "$BATS_TEST_TMPDIR/instructions"
  instructions="$BATS_TEST_TMPDIR/instructions"
}

@test "the base stage consumes the original pinned Isaac Lab 3.0.0 image" {
  local pin='nvcr.io/nvidia/isaac-lab:3.0.0@sha256:f70acc9ed3bc3fc67099a0c5715379c432cc9965623cabbaf54f74599997e245'
  local global_args
  global_args="$(awk 'toupper($1) == "FROM" {exit} toupper($1) == "ARG" {print $2}' "$instructions" | tr -d "\"'")"
  grep -Fxq "BASE_IMAGE=$pin" <<< "$global_args"
  grep -Eiq '^FROM[[:space:]]+[$](BASE_IMAGE|\{BASE_IMAGE\})[[:space:]]+AS[[:space:]]+base[[:space:]]*$' "$instructions"
}

@test "sys feeds devel-base and devel, with devel-test and headless leaves" {
  local stages
  stages="$(awk 'toupper($1) == "FROM" && toupper($(NF-1)) == "AS" {print $(NF-2), $NF}' "$instructions")"
  grep -Eq '^([$]BASE_IMAGE|[$]\{BASE_IMAGE\}|base) sys$' <<< "$stages"
  grep -Fxq 'sys devel-base' <<< "$stages"
  grep -Fxq 'devel-base devel' <<< "$stages"
  grep -Fxq 'devel devel-test' <<< "$stages"
  grep -Fxq 'devel headless' <<< "$stages"
  run grep -E '^(devel-test|headless) ' <<< "$stages"
  [ "$status" -eq 1 ]
}

@test "sys uses the host build arguments and renames colliding accounts in place" {
  local sys arg
  sys="$(awk 'toupper($1) == "FROM" {in_sys = (tolower($NF) == "sys"); next} in_sys' "$instructions")"
  for arg in USER_NAME USER_UID USER_GID; do
    grep -Eq "^ARG[[:space:]]+${arg}(=|[[:space:]]|$)" <<< "$sys"
    grep -Eq "\\$\\{?${arg}\\}?" <<< "$sys"
  done
  grep -Eq 'usermod[[:space:]][^;&|]*(-l[[:space:]]|--login[=[:space:]])' <<< "$sys"
  grep -Eq 'groupmod[[:space:]][^;&|]*(-n[[:space:]]|--new-name[=[:space:]])' <<< "$sys"
}

@test "recursive ownership and permission changes avoid official installation trees" {
  local recursive='(-[[:alpha:]]*R[[:alpha:]]*|--recursive)'
  local official='(/isaac-sim|/workspace/isaaclab|\$\{?ISAACLAB_PATH\}?)'
  run grep -En "(chown|chmod)[[:space:]][^;&|]*${recursive}[[:space:]][^;&|]*${official}" "$instructions"
  [ "$status" -eq 1 ]
}

@test "the image uses the bundled Isaac Lab without installing it, ROS 2 or streaming" {
  grep -Eq '^ENV[[:space:]].*ISAACLAB_PATH(=|[[:space:]])"?/workspace/isaaclab"?([[:space:]]|$)' "$instructions"
  run grep -Ein 'git[[:space:]]+clone|isaaclab\.sh[^;&|]*(--install|[[:space:]]-i([[:space:]]|$))|pip[[:space:]]+install[^;&|]*isaaclab|ros2|/opt/ros/|ros-(humble|jazzy|rolling)-|ros-apt-source|ros_distro|livestream|webrtc|streaming|^FROM .* AS stream([[:space:]]|$)' "$instructions"
  [ "$status" -eq 1 ]
}
