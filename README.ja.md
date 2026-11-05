![Franklyn](./images/banner.png)

[English](./README.md) | [简体中文](./README.zh-CN.md) | 日本語 | [Español](./README.es.md)

![](https://img.shields.io/badge/Quarkus-Version_3.28.5-04668d)
![](https://img.shields.io/badge/Java-21-blue)
![](https://img.shields.io/badge/Rust-1.91.1-lightblue)
![](https://img.shields.io/badge/Maven-Build-blue)
![](https://img.shields.io/badge/Bun-Build_Tool-04668d)
![](https://img.shields.io/badge/Vue.js-Frontend-blue)
![](https://img.shields.io/badge/Hugo-Docs-lightblue)
![](https://img.shields.io/badge/MIT-License-blue)
![](https://img.shields.io/badge/NIX-Building-04668d)
[![codecov](https://codecov.io/github/2526-4ahitm-itp/2526-4ahitm-franklyn/branch/main/graph/badge.svg?token=JL3NBVZT15)](https://codecov.io/github/2526-4ahitm-itp/2526-4ahitm-franklyn)
[![build result](https://build.opensuse.org/projects/home:franklyn/packages/franklyn/badge.svg?type=percent)](https://build.opensuse.org/package/show/home:franklyn/franklyn)

---

⚠️ 注意：この README はプロジェクトの開発に伴い、今後も変更される可能性があります。

## 📘 プロジェクト概要

Franklyn は、小テストや試験の際に生徒の現在の画面操作を教員の画面へリアルタイムで配信し、試験監督を支援するためのプロジェクトです。教員は表示を切り替えることができ、小さなダッシュボードでアクティブな全生徒の画面を一覧で監視したり、詳細ダッシュボードで個々の生徒の画面を表示したりできます。
また、Franklyn では過去の試験の録画を閲覧することもできます。さらに、今後の試験を予約するためのログイン機能も提供される予定です。

## 🛠️ インストール

### 📦 必要環境

- [Nix パッケージマネージャー](https://nixos.org/download/) または [Docker](https://docs.docker.com/engine/install/) / [Podman](https://podman.io/docs/installation)

---

### 🐳 Docker を使う場合

1. `./enter-env.sh` を実行します
   - 使い方：`./enter-env.sh [podman] [server|hugo|proctor|sentinel]`
   - 永続ボリューム付きの Nix Docker コンテナが起動し、ターミナルでシェルが開きます。
     その後は「❄️ Nix を使う場合」の手順に進んでください。

### ❄️ Nix を使う場合

#### プロジェクトをクローンして開発環境に入る：

```shell
git clone https://github.com/2526-4ahitm-itp/2526-4ahitm-franklyn
nix develop
```

#### **🔐 Sentinel のビルド**：

```shell
 cd sentinel
 cargo build --release
```

#### **🖥️ Server のビルド**：

```shell
 cd server
 mvn clean package -DskipTests=true
```

#### **🌐 Proctor のビルド**

```shell
cd proctor
bun install
# 開発サーバーを起動
bun run dev
# dist/ にビルド
bun run build
```

## 🎓 使い方

### 👨‍🎓 生徒の場合

教員が試験を開始すると、自動的にポップアップウィンドウが表示されます。名前を入力すると、試験に接続されます。

### 👩‍🏫 教員の場合

Franklyn Proctor にログインし、試験用アカウントのプレフィックス（例：`testD`）を選択して試験を開始してください。
その後、試験に参加した生徒の一覧を名前付きで確認できます。

## 👥 チーム

指導教員 🧭 - Thomas Stütz [GitHub](https://github.com/htl-leonding)、Christian Aberger [GitHub](https://github.com/caberger)

スクラムマスター 🌀 - Jakob Huemer-Fistelberger [GitHub](https://github.com/JakobHuemer)

開発者 💻 - Eldin Beganovic [GitHub](https://github.com/EldinBegano)

開発者 💻 - Gregor Geigenberger [GitHub](https://github.com/GregGeig)

開発者 💻 - Clemens Zangenfeind [GitHub](https://github.com/ClemiZ)

## 📄 ライセンス

[📝 MIT ライセンス](./LICENSE)

## 📘 その他のドキュメント

ドキュメントは[こちら](https://franklyn.htl-leonding.ac.at/en/docs/)をご覧ください（英語）。
