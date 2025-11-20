![Franklyn](./images/banner.png)

![](https://img.shields.io/badge/Quarkus-Version_3.28.5-04668d?style=for-the-badge)
![](https://img.shields.io/badge/Java-21-blue?style=for-the-badge)
![](https://img.shields.io/badge/Rust-1.90.0-lightblue?style=for-the-badge)
![](https://img.shields.io/badge/Maven-Build-blue?style=for-the-badge)
![](https://img.shields.io/badge/Bun-Build_Tool-04668d?style=for-the-badge)
![](https://img.shields.io/badge/Vue.js-Frontend-blue?style=for-the-badge)
![](https://img.shields.io/badge/Hugo-Docs-lightblue?style=for-the-badge)
![](https://img.shields.io/badge/MIT-License-blue?style=for-the-badge)
![](https://img.shields.io/badge/NIX-Building-04668d?style=for-the-badge)
---
⚠️ NOTE: This README is subject to further change during development of the project

## 📘 Project Description

Franklyn is a project that is meant to assist instructors by streaming current activities to the teachers screen during tests and exams. The program also allows the teacher to switch between different views, enabling monitoring of all students via a small dashboard that displays every active student screen, or viewing one individual screen in the detailed dashboard.
Franklyn will also allow the teacher to look at recordings of previous exams. There will also be a login system to schedule future tests.

## 🛠️ Installation

### 📦 Requirements

- [nix package manager](https://nixos.org/download/) or [docker](https://docs.docker.com/engine/install/) / [podman](https://podman.io/docs/installation)

---
### 🐳 Using Docker

1. Execute File `./enter-env.sh`
    * Usage: ./enter-env.sh [podman] [server|hugo|proctor|sentinel]


### ❄️ Using Nix

1. Execute command `nix develop`

2. For **🔐 Sentinel**:
    * Execute `cd sentinel`
    * Execute `cargo build --release`
3. For **🖥️ Server**:
    * Execute `cd server`
    * Execute `mvn clean package -DskipTests=true`
4. For **🌐 Proctor**
    * Execute `cd proctor`
    * Execute `bun run dev` for live preview
    * Execute `bun run build`to build to dist/

## 🎓 How to use

### 👨‍🎓 For Students
Just Start the Franklyn Service, enter your name and pin and you will be connected to the test.

### 👩‍🏫 For Teachers

Start the service and open the Franklyn Proctor Website

## 👥 Team

Supervisors 🧭 - Thomas Stütz [Github](https://github.com/htl-leonding), Christian Aberger [Github](https://github.com/caberger)

Scrum Master 🌀 - Jakob Huemer-Fistelberger [Github](https://github.com/JakobHuemer)

Developer 💻 - Eldin Beganovic [Github](https://github.com/EldinBegano)

Developer 💻 - Gregor Geigenberger [Github](github.com/GregGeig)

Developer 💻 - Clemens Zangenfeind [Github](https://github.com/ClemiZ)


## 📄 License
[📝 MIT License](./LICENSE)
