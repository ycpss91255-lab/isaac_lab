#!/usr/bin/env bats

setup() {
  cd "${BATS_TEST_DIRNAME}/../../.." || return 1
  smoke=script/ci/image_smoke.sh
  export SMOKE_IMAGE=local/bats-smoke:argument SMOKE_LOG="$BATS_TEST_TMPDIR/calls"
  export DOCKER_HOST="unix://$BATS_TEST_TMPDIR/no-docker.sock"
  # Record what the host script would send to Docker. Never execute image commands.
  cat > "$BATS_TEST_TMPDIR/docker" <<'STUB'
#!/usr/bin/env bash
set -eu
[[ "$1" == run ]]
shift
user=
while (( $# )); do
  case "$1" in
    "$SMOKE_IMAGE") break ;;
    --user|-u) user="$2"; shift ;;
    --user=*) user="${1#*=}" ;;
  esac
  shift
done
[[ "${1:-}" == "$SMOKE_IMAGE" ]]
shift
printf '%s\t%s\n' "$user" "$*" >> "$SMOKE_LOG"
if [[ "$*" == *'id -u'* || "$*" == *'id -g'* ]]; then
  [[ "$user" == "$(id -u):$(id -g)" ]] || exit 1
  if [[ "$*" == *'id -u'* ]]; then echo "${PROBE_UID:-$(id -u)}"; fi
  if [[ "$*" == *'id -g'* ]]; then echo "${PROBE_GID:-$(id -g)}"; fi
fi
[[ -z "${FAIL_PROBE:-}" || "$*" != *"$FAIL_PROBE"* ]]
STUB
  chmod +x "$BATS_TEST_TMPDIR/docker"
  export PATH="$BATS_TEST_TMPDIR:$PATH"
}

@test "the executable image smoke script lives under script/ci" {
  [ -f "$smoke" ]
  [ -x "$smoke" ]
  [ ! -e test/bats/smoke/shared/image_smoke.sh ]
  [ ! -e test/smoke/image_smoke.sh ]
}

@test "the supplied image receives both Lab launcher imports, CUDA, passwd and host identity probes" {
  "$smoke" "$SMOKE_IMAGE"
  local launcher='\$\{?ISAACLAB_PATH\}?/isaaclab\.sh"?[[:space:]]+-p'
  grep -Eq "${launcher}.*import .*isaacsim" "$SMOKE_LOG"
  grep -Eq "${launcher}.*import .*isaaclab([^[:alnum:]_]|$)" "$SMOKE_LOG"
  grep -Eq 'assert[[:space:]]+torch\.cuda\.is_available\(\)|sys\.exit\(not torch\.cuda\.is_available\(\)' "$SMOKE_LOG"
  grep -Eq 'getent[[:space:]]+passwd' "$SMOKE_LOG"
  grep -Eq '1000.*(-eq|==|!=)[[:space:]]*1([^0-9]|$)' "$SMOKE_LOG"
  grep -Fq 'id -u' "$SMOKE_LOG"
  grep -Fq 'id -g' "$SMOKE_LOG"
}

@test "each failed package, CUDA or passwd probe fails the image smoke command" {
  [ -x "$smoke" ]
  local probe
  for probe in isaacsim 'import isaaclab' 'cuda.is_available' 'getent passwd'; do
    FAIL_PROBE="$probe" run "$smoke" "$SMOKE_IMAGE"
    grep -Fq "$probe" "$SMOKE_LOG"
    [ "$status" -ne 0 ]
  done
}

@test "either a wrong UID or a wrong GID fails the image smoke command" {
  [ -x "$smoke" ]
  PROBE_UID="$(($(id -u) + 1))" run "$smoke" "$SMOKE_IMAGE"
  [ "$status" -ne 0 ]
  PROBE_GID="$(($(id -g) + 1))" run "$smoke" "$SMOKE_IMAGE"
  [ "$status" -ne 0 ]
}
