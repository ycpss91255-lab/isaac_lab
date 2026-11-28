[English](README.md) | [繁體中文](README.zh-TW.md) | [简体中文](README.zh-CN.md) | [日本語](README.ja.md)

# isaac_lab

本映像檔提供 Isaac Lab 3.0.0 與 Isaac Sim 6.2 的開發環境。Dockerfile 以 NVIDIA 官方 Isaac Lab 映像檔為基底，Docker 包裝腳本與 just 指令則由 `.base/` 子樹提供。[架構決策紀錄](doc/adr/0002-independent-lab-image.md)

## 建置與執行

安裝 Git、just 與含 Compose 外掛程式的 Docker。若要使用 GPU，請先設定 NVIDIA 容器執行環境。在儲存庫根目錄執行下列指令，建置並進入開發容器。

```sh
just docker build
just docker run
```

容器使用與主機相同的 UID 和 GID，工作區掛載於 `~/work`。Kit 與 NVIDIA 的快取會保存在工作區的 `isaac-sim/` 目錄。若要在背景執行無圖形介面的容器，請依序執行 `just docker build headless` 與 `just docker run -t headless -d`。

在容器內透過 Isaac Lab 隨附的啟動腳本執行 Python，即可使用內建的 PyTorch 環境。

```sh
"${ISAACLAB_PATH}/isaaclab.sh" -p -c 'import isaaclab, isaacsim, torch; print(torch.cuda.is_available())'
```

## 測試與更新

`static` 工作會執行 Bats、Hadolint 與 ShellCheck。在配備 NVIDIA GPU 的主機上執行 `script/ci/gpu_smoke_job.sh`，即可建置 `devel-test` 階段並檢查套件匯入、CUDA 與使用者身分。儲存庫取得 GPU 執行器存取權並設定 `GPU_RUNNER_ENABLED=true` 後，受信任的 CI 執行（含合併佇列）會進行 GPU 測試。`gate` 彙整結果，作為必要檢查。[測試清單與指令](doc/test/TEST.md)

升級映像檔時，請一併修改 Dockerfile 中 `ARG BASE_IMAGE` 的 NVIDIA 版本標籤與映像檔資訊清單摘要，更新測試中的固定版本，再重新執行靜態檢查與 GPU 測試。

## 授權條款

[Apache-2.0](LICENSE)
