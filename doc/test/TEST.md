# Test inventory

**29 bats tests** in this repository. The hosted static job runs 26. The other three run inside the `devel-test` image at build time.

| Suite | Tests | What it verifies |
| --- | ---: | --- |
| [CI](../../test/bats/static/ci_spec.bats) | 5 | Hosted tools, GPU workflow and build order, merge queue and gate |
| [Dockerfile](../../test/bats/static/dockerfile_spec.bats) | 5 | Image pin, stage ancestry, host accounts and bundled Lab installation |
| [Image smoke driver](../../test/bats/static/image_smoke_spec.bats) | 4 | Image argument and failure propagation for imports, CUDA, passwd, UID and GID using a Docker stub |
| [Repository layout](../../test/bats/static/repo_layout_spec.bats) | 8 | Base subtree, recipes, READMEs, ADRs, changelog, inventory and tracked text |
| [Setup](../../test/bats/static/setup_spec.bats) | 4 | Build arguments, networking, GPU and GUI modes, workspace and cache mounts |
| [Lab image](../../test/bats/smoke/devel-test/isaac_lab_spec.bats) | 3 | Unique UID 1000, configured login and executable Lab launcher |

Run the hosted checks locally from the repository root with a GPU-free test-tools container.

```sh
docker run --rm -v "$PWD":/work -w /work ghcr.io/ycpss91255-lab/test-tools:v0.43.0-rc7 \
  sh -ec 'bats test/bats/static && hadolint --config .hadolint.yaml Dockerfile && shellcheck script/entrypoint.sh script/ci/*.sh script/hooks/*/*.sh script/local/*.sh'
```

On the GPU runner, `script/ci/gpu_smoke_job.sh` builds the Compose service `test` with `just docker build test`. Building its `devel-test` stage runs Hadolint, ShellCheck and Bats over the Lab specs and the shared base smoke suites. The host driver then probes imports, CUDA and user identity in the resulting image. The base suites are maintained and counted separately under `.base/dist/test/bats/smoke/`.
