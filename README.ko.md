![Franklyn](./images/banner.png)

[English](./README.md) | [简体中文](./README.zh-CN.md) | [日本語](./README.ja.md) | [Español](./README.es.md) | 한국어

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

⚠️ 참고: 이 README는 프로젝트 개발 과정에서 계속 변경될 수 있습니다.

## 📘 프로젝트 소개

Franklyn은 테스트와 시험 중에 학생들의 현재 화면 활동을 교사의 화면으로 실시간 전송하여 감독을 돕기 위한 프로젝트입니다. 교사는 여러 보기 사이를 전환할 수 있어, 활성화된 모든 학생의 화면을 보여 주는 작은 대시보드로 전체 학생을 모니터링하거나, 상세 대시보드에서 학생 한 명의 화면을 개별적으로 볼 수 있습니다.
또한 Franklyn에서는 지난 시험의 녹화 영상을 다시 볼 수 있습니다. 앞으로 있을 시험을 예약할 수 있는 로그인 시스템도 제공될 예정입니다.

## 🛠️ 설치

### 📦 요구 사항

- [Nix 패키지 관리자](https://nixos.org/download/) 또는 [Docker](https://docs.docker.com/engine/install/) / [Podman](https://podman.io/docs/installation)

---

### 🐳 Docker 사용

1. `./enter-env.sh`를 실행합니다
   - 사용법: `./enter-env.sh [podman] [server|hugo|proctor|sentinel]`
   - 영구 볼륨이 연결된 Nix Docker 컨테이너가 시작되고 터미널에 셸이 열립니다.
     이후에는 `❄️ Nix 사용` 섹션을 이어서 진행하세요.

### ❄️ Nix 사용

#### 프로젝트를 클론하고 개발 환경에 들어가기:

```shell
git clone https://github.com/2526-4ahitm-itp/2526-4ahitm-franklyn
nix develop
```

#### **🔐 Sentinel 빌드**:

```shell
 cd sentinel
 cargo build --release
```

#### **🖥️ Server 빌드**:

```shell
 cd server
 mvn clean package -DskipTests=true
```

#### **🌐 Proctor 빌드**

```shell
cd proctor
bun install
# 개발 모드로 실행
bun run dev
# dist/에 빌드
bun run build
```

## 🎓 사용 방법

### 👨‍🎓 학생

교사가 시험을 시작하면 자동으로 팝업 창이 나타납니다. 이름을 입력하면 시험에 연결됩니다.

### 👩‍🏫 교사

Franklyn Proctor에 로그인한 뒤 시험용 계정 접두사(예: `testD`)를 선택하고 시험을 시작하세요.
그러면 시험에 참여한 학생 목록을 이름과 함께 확인할 수 있습니다.

## 👥 팀

지도 교사 🧭 - Thomas Stütz [GitHub](https://github.com/htl-leonding), Christian Aberger [GitHub](https://github.com/caberger)

스크럼 마스터 🌀 - Jakob Huemer-Fistelberger [GitHub](https://github.com/JakobHuemer)

개발자 💻 - Eldin Beganovic [GitHub](https://github.com/EldinBegano)

개발자 💻 - Gregor Geigenberger [GitHub](https://github.com/GregGeig)

개발자 💻 - Clemens Zangenfeind [GitHub](https://github.com/ClemiZ)

## 📄 라이선스

[📝 MIT 라이선스](./LICENSE)

## 📘 추가 문서

문서는 [여기](https://franklyn.htl-leonding.ac.at/en/docs/)에서 확인할 수 있습니다(영어).
