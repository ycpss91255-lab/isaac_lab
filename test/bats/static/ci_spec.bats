#!/usr/bin/env bats

setup() {
  cd "${BATS_TEST_DIRNAME}/../../.." || return 1
  workflow="$BATS_TEST_TMPDIR/main.json"
  yq -o json '.' .github/workflows/main.yaml > "$workflow"
}

@test "the merge queue requests the same GPU check and the base version monitor exists" {
  jq -e '.on | if type == "array" then index("merge_group") != null
    else has("merge_group") and ((.merge_group.types // ["checks_requested"]) | index("checks_requested") != null) end' "$workflow"
  local condition
  condition="$(jq -r '.jobs["gpu-smoke"].if // ""' "$workflow")"
  run grep -E "!=[[:space:]]*['\"]merge_group['\"]|['\"]merge_group['\"][[:space:]]*!=" <<< "$condition"
  [ "$status" -eq 1 ]
  if [[ "$condition" == *github.event_name* ]]; then
    grep -Eq "github.event_name[[:space:]]*(!=[[:space:]]*['\"]pull_request|==[[:space:]]*['\"]merge_group)|contains\(.*merge_group" <<< "$condition"
  fi
  [ -f .github/workflows/base-version-monitor.yaml ]
}

@test "the hosted static job runs the static Bats suite and linters inside test-tools" {
  jq -e '.jobs.static["runs-on"] | strings | startswith("ubuntu-")' "$workflow"
  local commands
  commands="$(jq -r --arg image 'ghcr.io/ycpss91255-lab/test-tools' '
    .jobs.static | (.container | if type == "object" then .image else . // "" end) as $container
    | .steps[] | select(($container | startswith($image))
      or ((.run // "") | test("docker +run[^;&|]*" + $image))
      or ((.uses // "") | startswith("docker://" + $image)))
    | .run // .with.args' "$workflow")"
  grep -Eq 'bats[[:space:]][^;&|]*test/bats/static' <<< "$commands"
  grep -Eq 'hadolint[[:space:]][^;&|]*Dockerfile' <<< "$commands"
  grep -Eq 'shellcheck[[:space:]]' <<< "$commands"
}

@test "gpu-smoke calls the organization GPU workflow with the repository smoke job" {
  jq -e '.jobs["gpu-smoke"]
    | (.uses | startswith("ycpss91255-lab/.github/.github/workflows/gpu-self-hosted.yml@"))
    and (.with["run-script"] | ltrimstr("./") == "script/ci/gpu_smoke_job.sh")' "$workflow"
  [ -x script/ci/gpu_smoke_job.sh ]
}

@test "the GPU job builds devel-test through just before passing the image to smoke" {
  local job
  job="$(sed '/^[[:space:]]*#/d' script/ci/gpu_smoke_job.sh | sed ':a; /\\$/ {N; s/\\\n/ /; ba;}')"
  # The base wrapper builds Compose service names. Service test targets Dockerfile stage devel-test.
  awk '
    /just[[:space:]]+docker[[:space:]]+build[[:space:]]+((-t|--target)[[:space:]]+)?test[[:space:]]*$/ {build = NR}
    /script\/ci\/image_smoke\.sh["\047]?[[:space:]]+[^[:space:]#]/ {smoke = NR}
    END {exit !(build && smoke > build)}
  ' <<< "$job"
  run grep -E '(^|[;&][[:space:]]*)[[:space:]]*docker[[:space:]]+(buildx[[:space:]]+)?build[[:space:]]' <<< "$job"
  [ "$status" -eq 1 ]
}

@test "gate always aggregates every other job and checks its result" {
  jq -e '.jobs as $jobs | $jobs.gate
    | (.if | gsub("[${}[:space:]]"; "") == "always()")
    and ((.needs | sort) == ($jobs | del(.gate) | keys))
    and (.needs | contains(["static", "gpu-smoke"]))' "$workflow"
  local gate
  gate="$(jq -r '.jobs.gate.steps' "$workflow")"
  grep -Eq 'needs(\.\*\.result|\.[a-z_-]+\.result|\)| \|)' <<< "$gate"
  grep -Eq 'exit [1-9]|setFailed|throw ' <<< "$gate"
}
