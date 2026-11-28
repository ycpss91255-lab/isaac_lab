# 0002. Build Isaac Lab independently on the shared base subtree

**Status** Accepted. Supersedes [ADR 0001](0001-image-only-difference-from-isaac.md).  
**Date** 2026-11-28

## Context

ADR 0001 assumed that changing the parent image would be enough to reuse the Isaac Sim Dockerfile. Upstream chose to ship Isaac Sim on its own in isaac#475. Its subsequent removal of Isaac Lab, PyTorch and xacro added tests for their absence, which conflict with this image's purpose. [isaac#475](https://github.com/ycpss91255-lab/isaac/issues/475) and [isaac#480](https://github.com/ycpss91255-lab/isaac/issues/480)

## Decision

Maintain the Lab Dockerfile here. Pin the official NVIDIA Isaac Lab image by tag and digest in `BASE_IMAGE` and use its bundled launcher and Python environment. Import the shared base infrastructure directly as the `.base/` subtree, initially at `v0.43.0-rc7`, the version used by the sibling Isaac repository.

Adapt the host account handling from isaac#474. Remove the duplicate UID 1000 login while preserving its files, reuse matching numeric IDs, and grant the host account access through the official group. This avoids copying the installation trees into a new layer to change ownership. [isaac#474](https://github.com/ycpss91255-lab/isaac/issues/474)

## Consequences

Base upgrades update the shared Docker wrappers and just recipes. This repository owns the Lab image pin, stage configuration and smoke probes. The hosted job validates the configuration and scripts, and the GPU job builds the test image and exercises the bundled Python environment.

## Rejected alternatives

- Building the sibling Dockerfile on a Lab adapter would inherit tests that require Lab packages to be absent.
- Importing the entire Isaac repository as a subtree would nest its own base subtree and break the base upgrade path.
- Installing Lab on the Isaac Sim image would duplicate NVIDIA's packaging and make this repository responsible for matching Lab, Sim and PyTorch versions.
