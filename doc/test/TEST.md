# Static test inventory

**18 bats tests**

Run `just test` to execute the [repository layout spec](../../test/bats/smoke/repo_layout_spec.bats) in the test-tools container.

| # | What the test checks |
| --- | --- |
| 1 | The Dockerfile pins the official Isaac Lab base by tag and SHA-256 digest. |
| 2 | The adapter removes the duplicate `isaaclab` passwd entry. |
| 3 | The Dockerfile omits cloning and installing Isaac Lab. |
| 4 | All four language editions of the README exist. |
| 5 | Each README documents the pending isaac#474 sync. |
| 6 | The image-layering ADR exists. |
| 7 | The ADR covers `BASE_IMAGE`, the submodule, isaac#474 and rejected alternatives. |
| 8 | `build-isaac` depends on the adapter build and passes its image to the upstream Dockerfile. |
| 9 | The `isaac` submodule has the expected path and upstream URL. |
| 10 | The changelog contains an Unreleased section. |
| 11 | The documented Bats total matches the number of test declarations. |
| 12 | Repository text outside the submodule excludes the attribution and host-path patterns in the spec. |
| 13 | The image smoke script is executable. |
| 14 | The smoke script checks the passwd UID field for exactly one entry with UID 1000. |
| 15 | The CI workflow references the organization's reusable GPU workflow. |
| 16 | The CI workflow runs when the merge queue requests checks. |
| 17 | The `gpu-smoke` job condition allows merge groups. |
| 18 | The `gate` job always runs after `docs-unit` and `gpu-smoke`. |
