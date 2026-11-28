[English](README.md) | [繁體中文](README.zh-TW.md) | [简体中文](README.zh-CN.md) | [日本語](README.ja.md)

# isaac_lab

本镜像提供 Isaac Lab 3.0.0 和 Isaac Sim 6.2 的开发环境。Dockerfile 使用 NVIDIA 官方 Isaac Lab 镜像作为基础镜像，Docker 包装脚本和 just 命令由 `.base/` 子树提供。[架构决策记录](doc/adr/0002-independent-lab-image.md)

## 构建与运行

安装 Git、just 和带有 Compose 插件的 Docker。如需使用 GPU，请先配置 NVIDIA 容器运行时。在仓库根目录执行以下命令，构建并进入开发容器。

```sh
just docker build
just docker run
```

容器使用与宿主机相同的 UID 和 GID，工作区挂载在 `~/work`。Kit 和 NVIDIA 的缓存保存在工作区的 `isaac-sim/` 目录中。如需在后台运行无图形界面的容器，请依次执行 `just docker build headless` 和 `just docker run -t headless -d`。

在容器中通过 Isaac Lab 自带的启动脚本运行 Python，即可使用随镜像提供的 PyTorch 环境。

```sh
"${ISAACLAB_PATH}/isaaclab.sh" -p -c 'import isaaclab, isaacsim, torch; print(torch.cuda.is_available())'
```

## 测试与更新

`static` 作业运行 Bats、Hadolint 和 ShellCheck。在配备 NVIDIA GPU 的主机上运行 `script/ci/gpu_smoke_job.sh`，即可构建 `devel-test` 阶段并检查包导入、CUDA 和用户身份。仓库获得 GPU 运行器访问权限并设置 `GPU_RUNNER_ENABLED=true` 后，受信任的 CI 运行（含合并队列）会执行 GPU 测试。`gate` 汇总结果，作为必需检查。[测试清单与命令](doc/test/TEST.md)

升级镜像时，请同时修改 Dockerfile 中 `ARG BASE_IMAGE` 的 NVIDIA 版本标签和镜像清单摘要，更新测试中的固定版本，再重新运行静态检查和 GPU 测试。

## 许可证

[Apache-2.0](LICENSE)
