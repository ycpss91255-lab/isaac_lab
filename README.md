[English](README.md) | [繁體中文](README.zh-TW.md) | [简体中文](README.zh-CN.md) | [日本語](README.ja.md)

# isaac_lab

This development image follows [isaac](https://github.com/ycpss91255-lab/isaac) with one change. The base is NVIDIA's official `nvcr.io/nvidia/isaac-lab` image, which bundles Isaac Sim 6.2 and Isaac Lab 3.0.0. Upstream uses `nvcr.io/nvidia/isaac-sim`.

## How the image is built

The [Dockerfile](Dockerfile) builds the `lab-base` adapter. It removes the duplicate passwd entry for UID 1000 and sets `ISAACLAB_PATH`. The `isaac/` submodule pins upstream to a commit. The experimental `just build-isaac` first builds the adapter, then passes its image tag to `isaac/Dockerfile` through `BASE_IMAGE` and builds the upstream `devel` target. See the [architecture decision](doc/adr/0001-image-only-difference-from-isaac.md).

For local development only, container names use the `cc-lab-` prefix and image names use `ycpss91255/cc-`.

## Quick start

Install Git, just and Docker. The smoke check also needs an NVIDIA GPU accessible to Docker.

```sh
just submodule  # Initialize the pinned upstream checkout
just build      # Build the lab-base adapter
just smoke      # Check imports, CUDA, UID/GID and the UID 1000 entry
just test       # Run the static Bats suite
just lint       # Run Hadolint and ShellCheck
```

## Run Python

Inside the container, use the Isaac Lab launcher to select the environment containing Isaac Lab and PyTorch. The Isaac Sim launcher `/isaac-sim/python.sh` uses a different environment.

```sh
"${ISAACLAB_PATH}/isaaclab.sh" -p -c 'import isaaclab, isaacsim, torch; print(torch.cuda.is_available())'
```

## Update the base image

The current pin is `nvcr.io/nvidia/isaac-lab:3.0.0@sha256:f70acc9ed3bc3fc67099a0c5715379c432cc9965623cabbaf54f74599997e245`.

Choose the official release tag and look up its manifest digest in NVIDIA's registry. Update both values in the Dockerfile's `ARG BASE_IMAGE`, update the pin in all four READMEs, then run `just build`, `just smoke`, `just test` and `just lint`.

## Pending upstream changes

- **isaac#474** will create the container user with the host UID/GID. Once it merges, update the submodule pin to inherit that behavior. User creation stays upstream.
- Upstream still installs Isaac Lab in its `sys`/`devel` build and plans to remove that step. `just build-isaac` remains experimental until the pinned commit includes the removal.

## CI

The hosted `docs-unit` job runs Bats, Hadolint and ShellCheck. After it passes, `gpu-smoke` builds and tests the adapter on a self-hosted GPU runner for pushes, manual runs and same-repository pull requests. Enable it by granting this repository access to the runner group and setting the repository variable `GPU_RUNNER_ENABLED` to `true`.

## License

[Apache-2.0](LICENSE)
