[English](README.md) | [繁體中文](README.zh-TW.md) | [简体中文](README.zh-CN.md) | [日本語](README.ja.md)

# isaac_lab

這個開發映像檔與上游 [isaac](https://github.com/ycpss91255-lab/isaac) 的唯一差異是基底映像檔。此處採用 NVIDIA 官方的 `nvcr.io/nvidia/isaac-lab`，內含 Isaac Sim 6.2 與 Isaac Lab 3.0.0。上游使用 `nvcr.io/nvidia/isaac-sim`。

## 映像檔的建置方式

[Dockerfile](Dockerfile) 建置 `lab-base` 適配層，移除 UID 1000 重複的 passwd 紀錄，並設定 `ISAACLAB_PATH`。`isaac/` 子模組將上游版本固定在特定提交。實驗性的 `just build-isaac` 會先建置適配層，再透過 `BASE_IMAGE` 將其映像檔標籤傳給 `isaac/Dockerfile`，建置上游的 `devel` 目標。詳見[架構決策紀錄](doc/adr/0001-image-only-difference-from-isaac.md)。

容器名稱前綴 `cc-lab-` 與映像檔名稱前綴 `ycpss91255/cc-` 僅供本機開發使用。

## 快速開始

請先安裝 Git、just 與 Docker。執行煙霧測試還需要 Docker 能存取的 NVIDIA GPU。

```sh
just submodule  # 初始化子模組，取出指定版本的上游原始碼
just build      # 建置 lab-base 適配層
just smoke      # 檢查模組匯入、CUDA、UID/GID 與 UID 1000 的紀錄
just test       # 執行 Bats 靜態測試
just lint       # 執行 Hadolint 與 ShellCheck
```

## 執行 Python

在容器內使用 Isaac Lab 啟動腳本，即可選用含有 Isaac Lab 與 PyTorch 的 Python 環境。Isaac Sim 的 `/isaac-sim/python.sh` 使用另一個環境。

```sh
"${ISAACLAB_PATH}/isaaclab.sh" -p -c 'import isaaclab, isaacsim, torch; print(torch.cuda.is_available())'
```

## 更新基底映像檔

目前固定使用 `nvcr.io/nvidia/isaac-lab:3.0.0@sha256:f70acc9ed3bc3fc67099a0c5715379c432cc9965623cabbaf54f74599997e245`。

選定官方版本標籤後，從 NVIDIA 的映像檔登錄服務查出對應的 manifest digest。在 Dockerfile 的 `ARG BASE_IMAGE` 同時更新標籤與 digest，並更新四份 README 中的映像檔版本與 digest，然後執行 `just build`、`just smoke`、`just test` 與 `just lint`。

## 待上游完成的變更

- **isaac#474** 將依主機的 UID/GID 建立容器使用者。合併後，更新子模組指向的提交即可採用此功能。使用者建立邏輯由上游維護。
- 上游目前仍在 `sys`/`devel` 建置過程中安裝 Isaac Lab，並計畫移除此步驟。在子模組更新至包含該變更的提交之前，`just build-isaac` 維持實驗性質。

## 持續整合

`docs-unit` 在 GitHub 託管的執行器上執行 Bats、Hadolint 與 ShellCheck。通過後，推送、手動執行及來自同一儲存庫的拉取請求可觸發 `gpu-smoke`，在自架 GPU 執行器上建置並測試適配層。若要啟用，請允許此儲存庫使用該執行器群組，並將儲存庫變數 `GPU_RUNNER_ENABLED` 設為 `true`。

## 授權條款

[Apache-2.0](LICENSE)
