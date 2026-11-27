[English](README.md) | [繁體中文](README.zh-TW.md) | [简体中文](README.zh-CN.md) | [日本語](README.ja.md)

# isaac_lab

この開発用イメージと上流の [isaac](https://github.com/ycpss91255-lab/isaac) との違いは、ベースイメージだけです。ここでは Isaac Sim 6.2 と Isaac Lab 3.0.0 を同梱した NVIDIA 公式の `nvcr.io/nvidia/isaac-lab` を使います。上流は `nvcr.io/nvidia/isaac-sim` を使います。

## イメージの構成

[Dockerfile](Dockerfile) は `lab-base` アダプターをビルドし、UID 1000 の重複した passwd エントリを削除して `ISAACLAB_PATH` を設定します。`isaac/` サブモジュールは上流の特定のコミットを参照します。実験的な `just build-isaac` は、先にアダプターをビルドし、そのイメージタグを `BASE_IMAGE` として `isaac/Dockerfile` に渡して、上流の `devel` ターゲットをビルドします。経緯は[アーキテクチャ決定記録](doc/adr/0001-image-only-difference-from-isaac.md)を参照してください。

コンテナ名の接頭辞 `cc-lab-` とイメージ名の接頭辞 `ycpss91255/cc-` はローカル開発専用です。

## クイックスタート

Git、just、Docker をインストールしてください。スモークテストには Docker から利用できる NVIDIA GPU も必要です。

```sh
just submodule  # サブモジュールを初期化して指定のコミットを取得
just build      # lab-base アダプターをビルド
just smoke      # モジュールのインポート、CUDA、UID/GID、UID 1000 のエントリを確認
just test       # Bats の静的テストを実行
just lint       # Hadolint と ShellCheck を実行
```

## Python の実行

コンテナ内では、Isaac Lab と PyTorch が入った Python 環境を選ぶために Isaac Lab の起動スクリプトを使います。Isaac Sim の `/isaac-sim/python.sh` は別の環境を使います。

```sh
"${ISAACLAB_PATH}/isaaclab.sh" -p -c 'import isaaclab, isaacsim, torch; print(torch.cuda.is_available())'
```

## ベースイメージの更新

現在固定しているイメージは `nvcr.io/nvidia/isaac-lab:3.0.0@sha256:f70acc9ed3bc3fc67099a0c5715379c432cc9965623cabbaf54f74599997e245` です。

公式リリースのタグを選び、対応するマニフェストのダイジェストを NVIDIA のレジストリで確認します。Dockerfile の `ARG BASE_IMAGE` にあるタグとダイジェストを一緒に更新し、4 言語の README にも反映します。その後、`just build`、`just smoke`、`just test`、`just lint` を実行してください。

## 上流で対応予定の項目

- **isaac#474** では、ホストの UID/GID でコンテナユーザーを作成する予定です。マージ後、サブモジュールの参照先を更新して取り込みます。ユーザー作成処理は上流で管理します。
- 上流は現在も `sys`/`devel` のビルド中に Isaac Lab をインストールしており、このステップを削除する予定です。削除がサブモジュールの参照先に反映されるまで、`just build-isaac` は実験扱いです。

## CI

`docs-unit` は GitHub ホステッドランナーで Bats、Hadolint、ShellCheck を実行します。これが成功すると、プッシュ、手動実行、同じリポジトリからのプルリクエストでは、`gpu-smoke` がセルフホステッド GPU ランナーでアダプターをビルドしてテストします。有効にするには、リポジトリにランナーグループへのアクセスを許可し、リポジトリ変数 `GPU_RUNNER_ENABLED` を `true` に設定してください。

マージキューが `checks_requested` タイプの `merge_group` イベントを送信したときも、ワークフローが実行されます。`docs-unit` は通常どおり結果を報告します。`docs-unit` が成功し、かつ `GPU_RUNNER_ENABLED` が `true` の場合、`gpu-smoke` は実行結果を報告します。それ以外の場合はスキップとして表示されます。最後に `gate` が両ジョブの結果を集約して報告します。リポジトリの所有者が `gate` を必須のステータスチェックに指定したルールセットを適用し、マージキューを有効にします。

## ライセンス

[Apache-2.0](LICENSE)
