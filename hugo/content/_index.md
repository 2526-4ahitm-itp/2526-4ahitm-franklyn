---
title: Franklyn
---
<br>
⚠️ NOTE: This Landing Page is subject to further change during development of the project

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



## 👥 Team

Supervisors 🧭 - Thomas Stütz [Github](https://github.com/htl-leonding), Christian Aberger [Github](https://github.com/caberger)

Scrum Master 🌀 - Jakob Huemer-Fistelberger [Github](https://github.com/JakobHuemer)

Developer 💻 - Eldin Beganovic [Github](https://github.com/EldinBegano)

Developer 💻 - Gregor Geigenberger [Github](https://github.com/GregGeig)

Developer 💻 - Clemens Zangenfeind [Github](https://github.com/ClemiZ)


## 📄 License
[📝 MIT License](./LICENSE)

## 📘 Additional Documentation

Also checkout the [docs](./docs) or the [guide](./guide)

In the future our webinterface [proctor](./proctor)

For Developer Guides check the [project_guide](./docs/project_guide)
