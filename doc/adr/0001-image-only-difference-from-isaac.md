# 0001. Change the Isaac base image through a pinned submodule

**Status** Superseded by [ADR 0002](0002-independent-lab-image.md)  
**Date** 2026-11-27

## Context

The `isaac_lab` development image should track upstream `isaac` with one difference. Upstream starts from `nvcr.io/nvidia/isaac-sim`. This variant needs the official `nvcr.io/nvidia/isaac-lab` image, which ships Isaac Sim 6.2 and Isaac Lab 3.0.0 together. Upstream already exposes its base through the `BASE_IMAGE` build argument.

## Decision

Pin upstream to a commit through the [isaac submodule](../../.gitmodules). The local Dockerfile builds a `lab-base` stage from the official image, pinned by tag and digest. Both `ubuntu` and `isaaclab` have UID 1000 in that image. The adapter removes the extra `isaaclab` passwd entry and preserves its home directory, which is shared with root.

`just build` builds the adapter. After `just submodule`, the experimental `just build-isaac` builds the adapter and passes its local image tag as `BASE_IMAGE` to `isaac/Dockerfile`. It selects the upstream `devel` target and uses `isaac/` as the build context so upstream controls its own build inputs.

## Consequences

Upstream changes enter this repository through explicit submodule updates. A base-image update changes the tag and digest in the local Dockerfile and requires a new GPU smoke run. Run Python through `"${ISAACLAB_PATH}/isaaclab.sh" -p` to use the environment that contains Isaac Lab and PyTorch. The Isaac Sim launcher `/isaac-sim/python.sh` uses a different environment.

## Rejected alternatives

| Alternative | Reason |
| --- | --- |
| Copy upstream code | Each upstream change would require a manual port, allowing the two copies to drift. |
| Import upstream as a Git subtree | This imports a large history. Upstream already carries a subtree under `.base/`, and nesting the subtree prefixes breaks its upgrade script. |
| Extend a published upstream image | Upstream publishes only the `isaac-stream-source` producer image. A downstream layer also cannot replace the `FROM` used to build its parent. |
| Call an upstream reusable workflow | Upstream has no reusable workflow for building its own image. |
| Follow the `isaac_ros_io` pattern | That seed repository extracts files and records their provenance in `SOURCE.md`. It cannot run independently or supply an image layer. |

## Open dependencies

- **isaac#474** will create the container user with the host UID and GID. Once it merges, update the submodule pin to pick up user creation. The adapter only removes the duplicate entry.
- Upstream still installs Isaac Lab in its `sys`/`devel` build. The maintainer plans to remove that installation. Until the pin includes that change, `just build-isaac` is experimental because it attempts to install Lab over the bundled copy.
