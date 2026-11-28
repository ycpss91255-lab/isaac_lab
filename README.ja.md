[English](README.md) | [繁體中文](README.zh-TW.md) | [简体中文](README.zh-CN.md) | [日本語](README.ja.md)

# isaac_lab

Isaac Lab 3.0.0 と Isaac Sim 6.2 の開発用イメージです。Dockerfile は NVIDIA 公式の Isaac Lab イメージを使用します。Docker のラッパースクリプトと just のレシピは `.base/` サブツリーで管理しています。[アーキテクチャ決定記録](doc/adr/0002-independent-lab-image.md)

## ビルドと起動

Git、just、Compose プラグイン付きの Docker をインストールします。GPU を使用する場合は NVIDIA コンテナランタイムも設定してください。リポジトリのルートで次のコマンドを実行すると、開発用イメージをビルドしてコンテナに入れます。

```sh
just docker build
just docker run
```

コンテナ内の UID と GID はホストと同じです。ワークスペースは `~/work` にマウントされ、Kit と NVIDIA のキャッシュはワークスペースの `isaac-sim/` に保存されます。画面を使わずバックグラウンドで起動するには、`just docker build headless`、`just docker run -t headless -d` の順に実行します。

コンテナ内では Isaac Lab 付属のランチャーから Python を起動すると、同梱の PyTorch 環境が使えます。

```sh
"${ISAACLAB_PATH}/isaaclab.sh" -p -c 'import isaaclab, isaacsim, torch; print(torch.cuda.is_available())'
```

## テストと更新

`static` ジョブは Bats、Hadolint、ShellCheck を実行します。NVIDIA GPU を搭載したホストで `script/ci/gpu_smoke_job.sh` を実行すると、`devel-test` ステージをビルドし、パッケージのインポート、CUDA、ユーザー ID を検証できます。リポジトリに GPU ランナーへのアクセス権を付与し、`GPU_RUNNER_ENABLED=true` を設定すると、マージキューを含む信頼済みの CI 実行で GPU テストが有効になります。必須チェックの `gate` が結果を集約します。[テスト一覧と実行方法](doc/test/TEST.md)

イメージの更新時は Dockerfile の `ARG BASE_IMAGE` に指定した NVIDIA のリリースタグとマニフェストのダイジェストを一緒に変更し、テストの期待値を更新してから静的チェックと GPU テストを実行してください。

## ライセンス

[Apache-2.0](LICENSE)
