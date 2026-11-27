[English](README.md) | [繁體中文](README.zh-TW.md) | [简体中文](README.zh-CN.md) | [日本語](README.ja.md)

# isaac_lab

这个开发镜像与上游 [isaac](https://github.com/ycpss91255-lab/isaac) 的唯一区别是基础镜像。这里使用 NVIDIA 官方的 `nvcr.io/nvidia/isaac-lab`，其中包含 Isaac Sim 6.2 和 Isaac Lab 3.0.0。上游使用 `nvcr.io/nvidia/isaac-sim`。

## 镜像构建方式

[Dockerfile](Dockerfile) 构建 `lab-base` 适配层，删除 UID 1000 重复的 passwd 记录，并设置 `ISAACLAB_PATH`。`isaac/` 子模块将上游版本固定在指定提交。实验性的 `just build-isaac` 先构建适配层，再通过 `BASE_IMAGE` 将其镜像标签传给 `isaac/Dockerfile`，构建上游的 `devel` 目标。详见[架构决策记录](doc/adr/0001-image-only-difference-from-isaac.md)。

容器名称前缀 `cc-lab-` 和镜像名称前缀 `ycpss91255/cc-` 仅用于本地开发。

## 快速开始

请先安装 Git、just 和 Docker。运行冒烟测试还需要 Docker 能够访问的 NVIDIA GPU。

```sh
just submodule  # 初始化子模块，检出指定版本的上游源码
just build      # 构建 lab-base 适配层
just smoke      # 检查模块导入、CUDA、UID/GID 和 UID 1000 的记录
just test       # 运行 Bats 静态测试
just lint       # 运行 Hadolint 和 ShellCheck
```

## 运行 Python

在容器内使用 Isaac Lab 启动脚本，即可选择包含 Isaac Lab 和 PyTorch 的 Python 环境。Isaac Sim 的 `/isaac-sim/python.sh` 使用另一个环境。

```sh
"${ISAACLAB_PATH}/isaaclab.sh" -p -c 'import isaaclab, isaacsim, torch; print(torch.cuda.is_available())'
```

## 更新基础镜像

当前固定使用 `nvcr.io/nvidia/isaac-lab:3.0.0@sha256:f70acc9ed3bc3fc67099a0c5715379c432cc9965623cabbaf54f74599997e245`。

选定官方版本标签后，从 NVIDIA 的镜像仓库查询对应的 manifest digest。在 Dockerfile 的 `ARG BASE_IMAGE` 中同时更新标签和 digest，并更新四份 README 中的镜像版本和 digest，然后运行 `just build`、`just smoke`、`just test` 和 `just lint`。

## 待上游完成的变更

- **isaac#474** 将按主机的 UID/GID 创建容器用户。合并后，更新子模块指向的提交即可使用该功能。创建用户的逻辑由上游维护。
- 上游目前仍在 `sys`/`devel` 构建过程中安装 Isaac Lab，并计划移除这一步骤。在子模块更新到包含该变更的提交之前，`just build-isaac` 保持实验状态。

## 持续集成

`docs-unit` 在 GitHub 托管的运行器上运行 Bats、Hadolint 和 ShellCheck。通过后，推送、手动运行和来自同一仓库的拉取请求可触发 `gpu-smoke`，在自托管 GPU 运行器上构建并测试适配层。要启用该任务，请允许此仓库使用该运行器组，并将仓库变量 `GPU_RUNNER_ENABLED` 设为 `true`。

## 许可证

[Apache-2.0](LICENSE)
