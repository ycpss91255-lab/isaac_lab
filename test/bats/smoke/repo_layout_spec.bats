#!/usr/bin/env bats
# Static checks for the isaac_lab repo layout. No Docker, no GPU needed.

setup() {
  ROOT="$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)"
}

@test "Dockerfile pins the official isaac-lab image by tag and digest" {
  run grep -E '^ARG BASE_IMAGE="nvcr\.io/nvidia/isaac-lab:[0-9.]+@sha256:[0-9a-f]{64}"$' "${ROOT}/Dockerfile"
  [ "${status}" -eq 0 ]
}

@test "Dockerfile adapter drops the duplicate isaaclab passwd entry" {
  run grep -E 'userdel isaaclab' "${ROOT}/Dockerfile"
  [ "${status}" -eq 0 ]
}

@test "Dockerfile does not install Isaac Lab itself" {
  run grep -E 'git clone|isaaclab\.sh --install' "${ROOT}/Dockerfile"
  [ "${status}" -ne 0 ]
}

@test "four language READMEs exist" {
  for f in README.md README.zh-TW.md README.zh-CN.md README.ja.md; do
    [ -f "${ROOT}/${f}" ]
  done
}

@test "READMEs state the pending #474 sync" {
  for f in README.md README.zh-TW.md README.zh-CN.md README.ja.md; do
    grep -q 'isaac#474' "${ROOT}/${f}"
  done
}

@test "ADR for the image-only mechanism exists" {
  ls "${ROOT}"/doc/adr/0001-*.md
}

@test "ADR records the layering decision, pending dependency and rejected alternatives" {
  local adr=( "${ROOT}"/doc/adr/0001-*.md )
  for term in BASE_IMAGE submodule isaac#474; do
    grep -Fq "${term}" "${adr[0]}"
  done
  grep -iq '^## Rejected alternatives$' "${adr[0]}"
}

@test "build-isaac builds the upstream Dockerfile on the adapter image" {
  local recipe
  recipe="$(sed -n '/^build-isaac:/,/^$/p' "${ROOT}/justfile")"
  [[ "${recipe}" == *"build-isaac: build"* ]]
  [[ "${recipe}" == *"docker build -f isaac/Dockerfile --build-arg BASE_IMAGE={{image}}"* ]]
}

@test "isaac submodule points at the upstream repository" {
  grep -Eq '^[[:space:]]*path = isaac$' "${ROOT}/.gitmodules"
  grep -Eq '^[[:space:]]*url = https://github\.com/ycpss91255-lab/isaac\.git$' "${ROOT}/.gitmodules"
}

@test "CHANGELOG has an Unreleased section" {
  grep -q '^## \[Unreleased\]' "${ROOT}/doc/changelog/CHANGELOG.md"
}

@test "TEST.md total matches the bats test count" {
  total="$(grep -h '^@test' "${ROOT}"/test/bats/smoke/*.bats | wc -l)"
  grep -q "\*\*${total} bats tests\*\*" "${ROOT}/doc/test/TEST.md"
}

@test "no AI attribution, machine names or user paths in tracked text" {
  run grep -rIlEi 'co-authored-by: *claude|generated with claude|/home/[a-z]+/' \
    --exclude-dir=.git --exclude=.git --exclude-dir=isaac --exclude=repo_layout_spec.bats "${ROOT}"
  [ "${status}" -eq 1 ]
}

@test "smoke script exists and is executable" {
  [ -x "${ROOT}/test/smoke/image_smoke.sh" ]
}

@test "smoke checks for exactly one passwd entry with UID 1000" {
  grep -Fq '$(getent passwd | cut -d: -f3 | grep -cx 1000)" -eq 1' "${ROOT}/test/smoke/image_smoke.sh"
}

@test "CI workflow exists and GPU job goes through the org reusable workflow" {
  grep -q 'gpu-self-hosted.yml' "${ROOT}/.github/workflows/main.yaml"
}

@test "CI runs when the merge queue requests checks" {
  local trigger
  trigger="$(sed -n '/^on:/,/^permissions:/p' "${ROOT}/.github/workflows/main.yaml")"
  [[ "${trigger}" == *$'\n  merge_group:\n    types: [checks_requested]'* ]]
}

@test "gpu-smoke does not exclude merge groups" {
  local job
  job="$(sed -n '/^  gpu-smoke:/,/^  gate:/p' "${ROOT}/.github/workflows/main.yaml")"
  [[ "${job}" == *"github.event_name != 'pull_request'"* ]]
  [[ "${job}" != *"merge_group"* ]]
}

@test "gate always runs after docs-unit and gpu-smoke" {
  local job
  job="$(sed -n '/^  gate:/,$p' "${ROOT}/.github/workflows/main.yaml")"
  [[ "${job}" == *"if: always()"* ]]
  [[ "${job}" == *"needs: [docs-unit, gpu-smoke]"* ]]
}
