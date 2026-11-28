#!/usr/bin/env bats

setup() {
  cd "${BATS_TEST_DIRNAME}/../../.." || return 1
}

@test "the pinned base subtree replaces the isaac submodule" {
  [ ! -e .gitmodules ]
  [ ! -L .gitmodules ]
  [ ! -e isaac ]
  [ ! -L isaac ]
  [ "$(cat .base/.version)" = v0.43.0-rc7 ]
}

@test "the root justfile uses the base entry and all recipe files omit the old recipes" {
  [ -f justfile ]
  [ "$(readlink justfile)" = script/justfile ]
  local recipes
  recipes="$(find . -name .git -prune -o -name .base -prune -o \
    \( -iname '*justfile*' -o -name '*.just' \) -print)"
  while IFS= read -r file; do
    run grep -inE '^(alias[[:space:]]+|@)?(build-isaac|submodule)([[:space:]]|:)' "$file"
    [ "$status" -eq 1 ]
  done <<< "$recipes"
}

@test "all four README editions explain the base subtree and just docker build" {
  local file
  for file in README.md README.ja.md README.zh-CN.md README.zh-TW.md; do
    grep -Fiq '.base' "$file"
    grep -Eiq 'subtree|子樹|子树|サブツリー' "$file"
    grep -Eq 'just[[:space:]]+docker[[:space:]]+build' "$file"
    run grep -inEi 'submodule|サブモジュール|子模組|子模块|build-isaac|(pending|waiting|await|待|予定).*isaac#474|isaac#474.*(pending|will |予定|合併後|合并后)' "$file"
    [ "$status" -eq 1 ]
  done
}

@test "ADR 0002 records the decision, alternatives and upstream changes" {
  local docs=(doc/adr/0002-*.md)
  [ "${#docs[@]}" -eq 1 ]
  [ -f "${docs[0]}" ]
  local heading term
  for heading in Context Decision Consequences 'Rejected alternatives'; do
    grep -Eiq "^##[[:space:]]+${heading}[[:space:]]*$" "${docs[0]}"
  done
  for term in base subtree BASE_IMAGE 'isaac#474' 'isaac#475'; do
    grep -Fqi "$term" "${docs[0]}"
  done
  grep -Ei 'supersed.*0001|0001.*supersed' "${docs[0]}"
}

@test "ADR 0001 points readers to its superseding ADR 0002" {
  grep -Ei 'supersed.*0002|0002.*supersed' doc/adr/0001-*.md
}

@test "the Unreleased changelog records the base subtree migration" {
  local unreleased
  unreleased="$(awk '/^## / { show = ($0 ~ /^## \[Unreleased\]/) } show' doc/changelog/CHANGELOG.md)"
  grep -Fiq 'subtree' <<< "$unreleased"
}

@test "TEST.md reports the full static and image Bats inventory" {
  local total
  total="$(bats --count --recursive test/bats/static test/bats/smoke)"
  grep -Fiq "**${total} bats tests**" doc/test/TEST.md
  [ -z "$(find . -name .git -prune -o -name .base -prune -o -name pytest-baseline.txt -print)" ]
}

@test "tracked text outside the base subtree has no attribution or host identifiers" {
  # Use Git's tracked working files so local .env files and binary data are ignored.
  # -l keeps the matched text (including any configured private names) out of CI logs.
  local -a scan=(git -c safe.directory="$PWD" grep -Iil)
  local -a files=(-- . ':(exclude).base/**')
  local agent='(claude|chatgpt|codex|copilot|anthropic|openai)'
  local attribution="co-authored-by:.*${agent}|generated (by|with) [^[:alnum:]]*${agent}"
  local home_path='/(home|Users)/[[:alnum:]_.-]+([^[:alnum:]_.-]|$)'
  local host_prompt='[[:alnum:]_.-]+@[[:alnum:]_.-]+:~'
  run "${scan[@]}" -E -e "$attribution" -e "$home_path" -e "$host_prompt" "${files[@]}"
  [ "$status" -eq 1 ]
  local -a names
  local name
  IFS=, read -ra names <<< "${FORBIDDEN_NAMES:-}"
  for name in "${names[@]}"; do
    [ -n "$name" ] || continue
    run "${scan[@]}" -F -e "$name" "${files[@]}"
    [ "$status" -eq 1 ]
  done
}
