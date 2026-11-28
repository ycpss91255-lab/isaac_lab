#!/usr/bin/env bats

@test "the official UID 1000 has exactly one passwd entry" {
  local passwd
  passwd="$(getent passwd)"
  [ "$(awk -F: '$3 == 1000 {n++} END {print n+0}' <<< "$passwd")" -eq 1 ]
}

@test "the configured host UID resolves to USER_NAME" {
  local entry
  entry="$(getent passwd "${USER_UID:-1000}")"
  [ "${entry%%:*}" = "${USER_NAME:?expected the configured host user name}" ]
}

@test "the image supplies the bundled Isaac Lab launcher at ISAACLAB_PATH" {
  [ "${ISAACLAB_PATH:-}" = /workspace/isaaclab ]
  [ -f "$ISAACLAB_PATH/isaaclab.sh" ]
  [ -x "$ISAACLAB_PATH/isaaclab.sh" ]
}
