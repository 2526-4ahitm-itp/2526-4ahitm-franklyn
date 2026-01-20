![Franklyn](./images/banner.png)

![](https://img.shields.io/badge/Quarkus-Version_3.28.5-04668d?style=for-the-badge)
![](https://img.shields.io/badge/Java-21-blue?style=for-the-badge)
![](https://img.shields.io/badge/Rust-1.91.1-lightblue?style=for-the-badge)
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

1. Run `./enter-env.sh`
    * Usage: `./enter-env.sh [podman] [server|hugo|proctor|sentinel]`
    * A nix docker container with persistent volumes will start with a shell
      in the terminal and you can continue at `❄️ Using Nix`.


### ❄️ Using Nix

#### Clone the project and enter environment:

```shell
git clone https://github.com/2526-4ahitm-itp/2526-4ahitm-franklyn
nix develop
```

#### **🔐 Build Sentinel**:

```shell
 cd sentinel
 cargo build --release
 ```

#### **🖥️ For Server**:

```shell
 cd server
 mvn clean package -DskipTests=true
 ```

#### **🌐 For Proctor**

```shell
cd proctor
bun install
# run live
bun run dev
# build to dist/
bun run build
 ```

## 🎓 How to use

### 👨‍🎓 For Students
There will be an automatic pop-up window as soon as the teacher starts the test where you will enter your name and you will be connected to the test.

### 👩‍🏫 For Teachers

Just login to Franklyn Proctor, choose your test account prefix (e.g. `testD`) and start the test.
You can then see the list of participants that joined the test with their name.

## 👥 Team

Supervisors 🧭 - Thomas Stütz [Github](https://github.com/htl-leonding), Christian Aberger [Github](https://github.com/caberger)

Scrum Master 🌀 - Jakob Huemer-Fistelberger [Github](https://github.com/JakobHuemer), [Codeberg](https://codeberg.org/fistelberger)

Developer 💻 - Eldin Beganovic [Github](https://github.com/EldinBegano), [Codeberg](https://codeberg.org/EldinBegano)

Developer 💻 - Gregor Geigenberger [Github](https://github.com/GregGeig), [Codeberg](https://codeberg.org/Gregorskyy)

Developer 💻 - Clemens Zangenfeind [Github](https://github.com/ClemiZ), [Codeberg](https://codeberg.org/ClemiZ)


## 📄 License
[📝 MIT License](./LICENSE)

## 📘 Additional Documentation

Check out our docs [here](https://2526-4ahitm-itp.github.io/2526-4ahitm-franklyn/docs/)
