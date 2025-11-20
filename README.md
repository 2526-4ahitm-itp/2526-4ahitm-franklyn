![Franklyn](./images/banner.png)

![](https://img.shields.io/badge/Quarkus-Version_3.28.5-04668d?style=for-the-badge)
![](https://img.shields.io/badge/Java-21-blue?style=for-the-badge)
![](https://img.shields.io/badge/Rust-1.90.0-lightblue?style=for-the-badge)
![](https://img.shields.io/badge/Maven-Build-blue?style=for-the-badge)
![](https://img.shields.io/badge/Bun-Runtime-04668d?style=for-the-badge)
![](https://img.shields.io/badge/Vue.js-Frontend-blue?style=for-the-badge)
![](https://img.shields.io/badge/Hugo-Docs-lightblue?style=for-the-badge)
![](https://img.shields.io/badge/MIT-License-blue?style=for-the-badge)
---
NOTE: This README is subject to further change during development of the project

## Project Description

Franklyn is a project that is meant to assist instructors by streaming current activities to the teachers screen during tests and exams. The program also allows the teacher to switch between different views, enabling monitoring of all students via a small dashboard that displays every active student screen, or viewing one individual screen in the detailed dashboard.
Franklyn will also allow the teacher to look at recordings of previous exams. There will also be a login system to schedule future tests.

## Installation

1. Clone Github Repo
2. Execute command `Nix develop`
3. Use build tools to build each part of the project
4. Navigate to the server directory and execute `mvn quarkus:dev`
5. Navigate to the sentinel directory and execute `cargo build` then execute `./franklyn-sentinel`
6. Navigate to the proctor directory and execute `bun run build`

## How to use

### For Students
Just Start the Franklyn Service, enter your name and pin and you will be connected to the test.

### For Teachers

Start the Franklyn service, login with your teacher credentials and start your test, you can now view all of the students connected to the test via the overview dashboard or click at individual screens and monitor them in the detailed view.

## Team

Team Lead - Jakob Huemer-Fistelberger

Team Member - Eldin Beganovic

Team Member - Gregor Geigenberger

Team Member - Clemens Zangenfeind


## License

The License can be found using this link:

[MIT License](./LICENSE)
