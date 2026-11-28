# Changelog

## [Unreleased]

### Changed

- Replaced the Isaac adapter build with an independent Dockerfile and the shared base subtree at `v0.43.0-rc7`. The development and headless images use NVIDIA's pinned Isaac Lab 3.0.0 distribution and the host user's UID and GID.
- Moved the GPU image probes to `script/ci/image_smoke.sh`. CI runs static Bats and lint on a hosted runner and builds the test stage on the enabled GPU runner. The merge queue receives the combined `gate` result.
- The GPU job builds the test stage with `./script/build.sh test`, the wrapper behind `just docker build`, because the GPU runner has no `just`.

### Added

- A root `.gitattributes` with shared line endings for text, Windows scripts and binary files.
