[English](README.md) | [繁體中文](README.zh-TW.md) | [简体中文](README.zh-CN.md) | [日本語](README.ja.md)

# isaac_lab

A development image for Isaac Lab 3.0.0 and Isaac Sim 6.2. The Dockerfile starts from NVIDIA's official Isaac Lab distribution. The `.base/` subtree supplies the shared Docker wrappers and just recipes. [Architecture decision](doc/adr/0002-independent-lab-image.md)

## Build and run

Install Git, just and Docker with the Compose plugin. For GPU workloads, configure the NVIDIA container runtime. From the repository root, build and enter the development container.

```sh
just docker build
just docker run
```

The container uses your host UID and GID. Your workspace is mounted at `~/work`, and Kit and NVIDIA caches persist under `isaac-sim/` in the workspace. For a background container without a display, run `just docker build headless` and `just docker run -t headless -d`.

Inside the container, run Python through the bundled Isaac Lab launcher to use its PyTorch environment.

```sh
"${ISAACLAB_PATH}/isaaclab.sh" -p -c 'import isaaclab, isaacsim, torch; print(torch.cuda.is_available())'
```

## Checks and updates

The hosted `static` job runs Bats, Hadolint and ShellCheck. On an NVIDIA host, run `script/ci/gpu_smoke_job.sh` to build the `devel-test` stage and check imports, CUDA and user identity. CI enables this job for trusted runs, including the merge queue, when the repository has GPU runner access and `GPU_RUNNER_ENABLED=true`. The required check is `gate`. [Test inventory and commands](doc/test/TEST.md)

To update the image, change the NVIDIA release tag and manifest digest together in `ARG BASE_IMAGE` in the Dockerfile, update the pin assertion, then rerun the static and GPU checks.

## License

[Apache-2.0](LICENSE)
