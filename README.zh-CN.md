![Franklyn](./images/banner.png)

[English](./README.md) | 简体中文

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

⚠️ 注意：本 README 在项目开发过程中可能会继续修改。

## 📘 项目简介

Franklyn 是一个旨在协助监考老师的项目：在测验和考试期间，它会将学生当前的屏幕活动实时传输到教师的屏幕上。教师可以在不同视图之间切换：既可以通过小型仪表盘同时查看所有在线学生的屏幕，也可以在详细仪表盘中单独查看某一位学生的屏幕。
Franklyn 还允许教师回看以往考试的录像。此外，系统还将提供登录功能，用于安排未来的考试。

## 🛠️ 安装

### 📦 环境要求

- [Nix 包管理器](https://nixos.org/download/) 或 [Docker](https://docs.docker.com/engine/install/) / [Podman](https://podman.io/docs/installation)

---

### 🐳 使用 Docker

1. 运行 `./enter-env.sh`
   - 用法：`./enter-env.sh [podman] [server|hugo|proctor|sentinel]`
   - 这会启动一个带有持久化卷的 Nix Docker 容器，并在终端中打开一个 shell，
     之后请继续阅读 `❄️ 使用 Nix` 一节。

### ❄️ 使用 Nix

#### 克隆项目并进入开发环境：

```shell
git clone https://github.com/2526-4ahitm-itp/2526-4ahitm-franklyn
nix develop
```

#### **🔐 构建 Sentinel**：

```shell
 cd sentinel
 cargo build --release
```

#### **🖥️ 构建 Server**：

```shell
 cd server
 mvn clean package -DskipTests=true
```

#### **🌐 构建 Proctor**

```shell
cd proctor
bun install
# 本地实时运行
bun run dev
# 构建到 dist/
bun run build
```

## 🎓 使用方法

### 👨‍🎓 学生

教师开始考试后，屏幕上会自动弹出一个窗口。输入你的姓名后，即可连接到本场考试。

### 👩‍🏫 教师

登录 Franklyn Proctor，选择你的考试账号前缀（例如 `testD`），然后开始考试。
随后你就可以看到已加入考试的参与者列表及其姓名。

## 👥 团队

指导老师 🧭 - Thomas Stütz [GitHub](https://github.com/htl-leonding)，Christian Aberger [GitHub](https://github.com/caberger)

Scrum Master 🌀 - Jakob Huemer-Fistelberger [GitHub](https://github.com/JakobHuemer)

开发者 💻 - Eldin Beganovic [GitHub](https://github.com/EldinBegano)

开发者 💻 - Gregor Geigenberger [GitHub](https://github.com/GregGeig)

开发者 💻 - Clemens Zangenfeind [GitHub](https://github.com/ClemiZ)

## 📄 许可证

[📝 MIT 许可证](./LICENSE)

## 📘 更多文档

请在[这里](https://franklyn.htl-leonding.ac.at/en/docs/)查看我们的文档（英文）。
