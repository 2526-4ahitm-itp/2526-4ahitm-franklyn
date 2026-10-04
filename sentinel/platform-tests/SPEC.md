# Sentinel Platform Tests — Specification

> **Status:** Draft (2026-10-04). Nothing in this spec is implemented yet.
> **This file is the contract.** Change this spec first, then the harness. A system counts as
> "supported" in user docs only if it is in the matrix (§4) and passes its required tiers.
> Requirement markers: `implemented` | `partial` | `not-implemented`.

> **Blocking open item:** result reporting (§9) is undecided. **Before starting implementation, ask
> the maintainer again** how results should be reported. Do not pick a channel on your own.

## 1. Purpose

Franklyn Sentinel runs on students' own machines across many operating systems, install channels,
and display servers. Screen capture uses a different backend on each (`ximagesrc` on X11,
`pipewiresrc` via the XDG ScreenCast portal on Wayland, `d3d11screencapturesrc` on Windows; see
`sentinel/src/recorder.rs`). Native packages also depend on the host's GStreamer and PipeWire,
while the portable bundle ships its own. A green `nix build .#franklyn-sentinel-check` proves none
of this works on a real student machine.

This spec defines a nightly test run on self-hosted VMs. It installs the **publicly released stable**
Sentinel through each real install channel and proves it installs, captures the screen, and streams
to a server.

### Goals
- Detect breakage of the *shipped* stable release on every supported system, including breakage
  caused by distro updates (e.g. a Tumbleweed snapshot changing GStreamer).
- Exercise the real install channels students use (APT repo, OBS repo, curl installer, release zip).
- Make adding a new system (Fedora, Arch, Flatpak, …) a matter of adding one profile (§5.2).

### Non-goals
- Testing unreleased builds (PR or `main` builds). Existing PR CI stays as is.
- aarch64. Release builds include aarch64, but only x86_64 is tested (§10, D-6).
- Load or performance testing of the server.
- Automating GNOME/KDE Wayland portal dialogs. These are manual (§3.4).

## 2. Terminology

| Term | Meaning |
|---|---|
| **System** | One OS release plus one install channel, e.g. `ubuntu-2204/apt`. Each row in §4 is one system. |
| **VM** | One libvirt guest per OS release. A VM hosts one or more systems: its native package plus the Linux portable. |
| **Channel** | How Sentinel is obtained: `apt`, `obs`, `installer` (curl \| bash), `tarball` (manual portable extract), `zip` (Windows portable). |
| **Session** | Display server the tests run under: `x11` (Xorg + lightweight WM), `sway` (Wayland via wlroots), `win` (Windows interactive desktop). |
| **Tier** | Depth of a test: L1 install/smoke, L2 capture, L3 join + stream, M manual (§3). |
| **Run** | One nightly execution over all VMs. |
| **Golden snapshot** | Clean libvirt snapshot of a VM that every run reverts to. |

## 3. Test tiers

Every automated test sets `FRANKLYN_TELEMETRY=false` so test runs never reach Sentry.

Tiers are cumulative per system. Running L2 requires L1 to pass, and running L3 requires L2 to pass
in the same session. A failed lower tier marks the higher tiers `blocked`, not `fail`.

### 3.1 L1 — Install & smoke — `not-implemented`

Runs once per system (not per session).

- **L1.1 Install.** Install through the channel exactly as the student docs say
  (`hugo/content/en/guide/students/installation.md`), from the public stable source. Exit code 0.
- **L1.2 Version.** `franklyn --version` exits 0 and prints `Franklyn Sentinel v<X>`. `<X>` equals the
  latest non-prerelease GitHub release tag. A mismatch is a fail: the channel serves a stale version.
- **L1.3 Licenses.** `PAGER=cat franklyn --licenses` exits 0 and prints the project license header.
  (Windows: no pager, plain run.)
- **L1.4 Linkage** (Linux, `apt`/`obs`). `ldd $(command -v franklyn)` reports no `not found`.
- **L1.5 Desktop integration** (Linux, `apt`/`obs`/`installer`). `franklyn-sentinel.desktop` and
  hicolor icons are installed where the channel promises.
- **L1.6 Installer contract** (`installer` only). Re-running the installer converges (idempotent).
  `--uninstall` removes exactly the manifest paths. Behavior must match
  `hugo/static/scripts/sentinel-install.md`.
- **L1.7 Uninstall** (all channels). Package removal / installer `--uninstall` / zip folder deletion
  leaves no Sentinel binary on `PATH`.

L1.7 runs last, after L2/L3 have used the install.

### 3.2 L2 — Capture selftest — `not-implemented`

Runs once per system **per session** (`x11` and `sway` on Linux, `win` on Windows).

Depends on Sentinel change **S-1** (§7): a hidden `franklyn selftest capture` subcommand. It runs the
same backend detection and GStreamer pipeline as `join`, with no auth and no network.

Procedure:
1. The harness shows a full-screen test pattern containing a per-run nonce (high-contrast pattern
   plus the nonce as a QR code). Linux: an image viewer in the session. Windows: a borderless
   PowerShell/WinForms window.
2. Run `franklyn selftest capture --frames 5 --timeout 30 --out <dir>`.

Pass criteria:
- **L2.1** Exit code 0 within the timeout.
- **L2.2** `<dir>` contains ≥ 5 files that decode as valid JPEGs.
- **L2.3** Frame resolution equals the session's output resolution.
- **L2.4** Frames are not blank: luminance standard deviation is above a fixed threshold. This
  catches the black-frame failure mode common with portal/PipeWire capture.
- **L2.5** (SHOULD) The nonce QR decodes from ≥ 1 frame. This proves the frame is live, not stale.
- **L2.6** `result.json` reports the expected backend (`x11` → X11, `sway` → Wayland, `win` → Windows).

Sway runs use `xdg-desktop-portal-wlr` with `chooser_type = none` (output preselected), so the
portal needs no interaction. This is the only Wayland session that is automated.

### 3.3 L3 — Join & stream against staging — `not-implemented`

Runs once per system per session, after L2 passes in that session.

Sentinel is pointed at staging through config env overrides (`sentinel/src/config.rs` reads
`FRANKLYN_*`): `FRANKLYN_API_URL`, `FRANKLYN_OIDC_URL`, `FRANKLYN_OIDC_REALM`,
`FRANKLYN_OIDC_CLIENT_ID`. The installed public binary is unchanged.

Procedure (all GraphQL calls go to staging, authenticated as the **test teacher**):
1. `createExam` with a unique title (`platform-test-<run-id>-<system>-<session>`) and a schedule
   window around now, then `startExam`. Read `pin` from the returned `Exam`.
2. Start `franklyn join <pin>` as the **test student**, with the test pattern from L2 on screen.
3. Scripted login (§6.4): read the auth URL from Sentinel's stdout (requires **S-2**). Complete the
   Keycloak login headlessly as the test student. The flow redirects to Sentinel's loopback callback
   (`http://127.0.0.1:<port>/callback`).
4. Within 60 s, `allStudents(examId)` contains a session for the test student. Record its `sentinelId`.
5. Let Sentinel stream for 60 s.
6. `endExam`. Wait ≤ 30 s for Sentinel to exit by itself, then terminate it. Graceful exit is
   recorded as informational; it is not a pass criterion until behavior is specified.
7. `generateSentinelVideo(sentinelId)`. Poll `videoStatus(sentinelId)` until `DONE` (fail on
   `FAILED` or after a 5 min timeout).
8. Download the video URL from `videoStatus`. It must be a non-empty MP4 with duration > 0.
9. Cleanup, always, also on failure: `deleteExam(examId)`.

Pass criteria: steps 1–8 succeed. If staging is unreachable or the teacher login fails before
step 2, L3 is marked `skipped (infra)`, not `fail` (§8).

### 3.4 M — Manual checklist — `not-implemented`

GNOME and KDE show a portal source-picker dialog on every capture, because Sentinel uses
`PersistMode::DoNot` (`sentinel/src/recorder.rs`). These sessions are not automated.

- Run **before each stable release** by a tester, on fresh golden-snapshot reverts. The tester
  signs off in the release checklist.
- The checklist lives in `sentinel/platform-tests/manual/CHECKLIST.md`. Per system's default
  desktop it covers: L2 and L3 steps performed by hand, the portal dialog appears and is
  understandable, choosing a monitor starts capture, and cancelling the dialog produces the
  "portal dialog was cancelled" error rather than a crash.
- Automating these sessions later requires Sentinel restore-token support. That is out of scope here
  (see S-3, §7).

## 4. System matrix (current)

All VMs are x86_64 and use the distro's **default desktop install**, like a student machine. The
image adds an Xorg + lightweight-WM session, a sway session, and the harness tools (§6.2).

| VM | OS | Systems (channel) | Automated sessions | Auto tiers | Manual (M) | Status |
|---|---|---|---|---|---|---|
| `ubuntu-2204` | Ubuntu 22.04 LTS | `apt` (stable), `installer`, `tarball` | `x11`, `sway` | L1–L3 | GNOME Wayland | not-implemented |
| `ubuntu-2604` | Ubuntu 26.04 LTS | `apt` (stable), `installer`, `tarball` | `x11`, `sway` | L1–L3 | GNOME Wayland | not-implemented |
| `debian-12` | Debian 12 | `apt` (stable), `installer`, `tarball` | `x11`, `sway` | L1–L3 | GNOME Wayland | not-implemented |
| `debian-13` | Debian 13 | `apt` (stable), `installer`, `tarball` | `x11`, `sway` | L1–L3 | GNOME Wayland | not-implemented |
| `tumbleweed` | openSUSE Tumbleweed | `obs`, `installer`, `tarball` | `x11`, `sway` | L1–L3 | KDE Plasma Wayland | not-implemented |
| `windows-11` | Windows 11 (latest GA feature update) | `zip` | `win` | L1–L3 | — | not-implemented |

Notes:
- **Version policy:** oldest and newest supported release per family (D-4). When a new release
  ships, it replaces the newest. When the oldest goes EOL, the next-oldest becomes the floor, and
  user docs are updated in the same change.
- **Linux portable** is tested on every Linux VM (D-8). `installer` and `tarball` install identical
  bits, so the split is: L1 runs for both, and L2/L3 run only on the `installer` install.
- **Native vs portable on one VM:** systems on the same VM run sequentially. Each is uninstalled
  (L1.7) before the next is installed. Order: native package, then installer, then tarball.
- **Ubuntu 26.04 / X11:** GNOME no longer ships an Xorg session. The `x11` session uses Xorg plus a
  lightweight WM (e.g. openbox), which stays installable. Verify when building the image.
- **Dependency risk to watch:** the `.deb` uses the *system* GStreamer. Its `Depends` line
  (`sentinel/default.nix`) does not list the package providing `pipewiresrc`
  (`gstreamer1.0-pipewire` on Debian/Ubuntu). The `sway` L2 run on the deb is meant to catch whether
  that matters on a default desktop install. Harness tools must not pull in GStreamer or PipeWire
  packages (§6.2), or they would mask this.

## 5. Future systems

### 5.1 Planned systems

These rows are planned and have status `not-implemented`. A row is added to §4 only once its
prerequisite is met.

| System | Prerequisite before testing | Tier expectations / specifics |
|---|---|---|
| **Fedora** (`obs`, `installer`) | Fedora_43/44 targets live in OBS `home:franklyn`, and the franklyn `.repo` file is published | L1–L3 on `x11` + `sway`. M on GNOME Wayland. L1 adds: the repo file uses `$releasever`. |
| **Arch Linux** (`installer`, later `aur`) | `installer`: none (portable already supports Arch). `aur`: AUR publish re-enabled in `release.yaml` | L1–L3. `aur` adds a `makepkg`/AUR-helper install step. Rolling distro: always updated (§6.3). |
| **Flatpak** (`flatpak`, Flathub) | Flathub manifest published | Sandbox: capture always via portal, even on X11 (if `ximagesrc` is not bundled/allowed). `/etc/franklyn/config.toml` is not visible, so L3 config overrides need `flatpak run --env=…`. L1 tests `flatpak run <app-id> --version`. Test on ≥ 1 deb-based and the rpm-based VM. |
| **Void Linux** (`installer`) | glibc variant only. Portable needs glibc ≥ 2.34. musl is unsupported (the installer warns and the `--version` gate decides) | L1–L3 on `x11` + `sway`. Add a musl VM as a negative test only if musl support is ever claimed. |
| **AppImage** (`appimage`) | AppImage artifact in release | L1: runs with and without FUSE (`--appimage-extract-and-run`). L2/L3 as portable. |
| **Windows installer** (`exe`) | Installer artifact in release | L1 adds: silent install, Start Menu entry, `PATH`, upgrade over previous stable, uninstall via Apps & Features / silent uninstaller leaves no files. L2/L3 as `zip`. |

### 5.2 Adding a system

1. Add a profile `sentinel/platform-tests/systems/<vm>.toml`. It declares: VM name, OS family,
   channels, install/uninstall/update commands per channel, sessions, required tiers, and the
   manual desktop.
2. Build the golden image as described in §6.2 and record its package list.
3. Add the row to §4 (or move it from §5.1) in the same change.
4. Run the matrix for that VM once by hand. The row's status becomes `implemented` only after
   L1–L3 pass.
5. Update the student installation docs if the system is newly supported.

## 6. Infrastructure

### 6.1 Host — `not-implemented`
- One Linux host with KVM, libvirt/QEMU, and outbound internet access. Hardware sizing is open (§10).
- Driven by a **systemd timer** (nightly, e.g. 02:00 Europe/Vienna). It calls a host script under
  `sentinel/platform-tests/harness/`.
- The host script holds an exclusive `flock`, so overlapping runs are impossible.
- VMs run sequentially by default. Parallelism is a config value bounded by host RAM.
- Not tied to GitHub Actions: no runner, no GitHub token required for testing.

### 6.2 Golden images — `not-implemented`
- Each image is built from: the distro's default desktop install, autologin for the test user,
  an Xorg + lightweight WM session, a sway session with `xdg-desktop-portal-wlr`
  (`chooser_type = none`), SSH server with the host's key, and the harness tools (image viewer, QR
  decoder, `curl`, `jq`).
- **Harness tools must not satisfy Sentinel's runtime dependencies** (GStreamer, PipeWire, OpenSSL
  beyond the default install). Each image build records its full package list next to the profile.
- Windows: OpenSSH server, autologon user, harness PowerShell scripts, and a scheduled task
  (§6.4) that runs in the interactive session.
- **Refresh:** rebuild or re-snapshot each golden image monthly, so the nightly update step (§6.3)
  stays short.

### 6.3 Per-VM run sequence — `not-implemented`
1. Revert to the golden snapshot and boot. Wait for SSH (timeout → `infra` failure).
2. **OS update:** `apt full-upgrade` / `zypper dup` / Windows Update optional. A failed update is
   an `infra` failure (D-7).
3. Record OS version, kernel, and versions of GStreamer, PipeWire, xdg-desktop-portal, and portal
   backends.
4. For each system on the VM: L1 → (per session: L2 → L3) → L1.7 uninstall.
5. Collect logs (`/var/log/franklyn-sentinel/` or `~/.local/share/franklyn-sentinel/logs/`;
   `%PROGRAMDATA%\franklyn-sentinel\logs` on Windows), frames, `result.json`, and harness logs.
6. Shut down and discard (revert to the snapshot on the next run).

### 6.4 Session control — `not-implemented`
- **Linux:** the harness switches the autologin session (`x11` / `sway`) and restarts the display
  manager. Tests run over SSH with the session's `DISPLAY` / `WAYLAND_DISPLAY` /
  `XDG_RUNTIME_DIR` / `DBUS_SESSION_BUS_ADDRESS` imported. `BROWSER=true` makes Sentinel's
  browser launch a successful no-op.
- **Windows:** SSH sessions have no desktop, so `d3d11screencapturesrc` cannot capture from them.
  Instead the host copies a job file over SSH and triggers a scheduled task that runs **in the
  autologon user's interactive session**. The task writes results to a known folder, and the host
  fetches them via `scp`. On Windows Sentinel opens the default browser; that window is ignored.
- **Scripted login:** a plain HTTP client follows the auth URL, parses the Keycloak login form,
  posts the test student's credentials, and follows redirects to the loopback callback. This needs
  no browser and no new dependency. If the school Keycloak login requires JavaScript or federates
  to an external IdP, this approach fails and needs a decision (§10).

### 6.5 Secrets — `not-implemented`
- Staging URL, the test student and test teacher credentials, and the OIDC realm/client live **only
  on the host**: a root-owned file with mode `600`, outside the repo.
- Secrets are injected into guests per run and removed afterwards (the revert discards them).
- Harness logs mask secrets. Credentials never appear in collected artifacts.

## 7. Required Sentinel changes

| ID | Change | Needed by | Status |
|---|---|---|---|
| **S-1** | Hidden subcommand `franklyn selftest capture [--frames N=5] [--timeout SECS=30] [--out DIR]`. Uses the same backend detection and pipeline as `join`. Writes JPEG frames and `result.json` (`backend`, `width`, `height`, `frames`, `elapsed_ms`, `error`). Distinct exit codes: 0 ok, and one each for no display server, portal cancelled, portal failed, pipeline failed, timeout. Hidden from `--help`. | L2 | not-implemented |
| **S-2** | Print the OIDC auth URL to stdout before opening the browser, e.g. "If your browser did not open, visit: <url>". Use `println!`, not tracing, so it doesn't reach Sentry logs. This also helps students when the browser fails to open. Today it is never shown (`sentinel/src/oidc.rs`). | L3 on all OSes (Windows ignores `$BROWSER`) | not-implemented |
| **S-3** | (Out of scope, recorded only.) Portal restore-token support, so GNOME/KDE can run unattended after a one-time grant. This would move M items to automated tiers. | Future | not-implemented |

S-1 and S-2 follow the normal Sentinel PR process (`nix build .#franklyn-sentinel-check`). They
must ship in a **stable release** before the nightly can use them, because the nightly only installs
public stable (D-5). Until then, L2 and L3 are `blocked` everywhere.

## 8. Results & failure policy — `not-implemented`

- Every tier produces a machine-readable record: `results/<run-id>/<vm>/<system>/<session>/<tier>.json`
  on the host. The record holds status, timings, Sentinel version, the OS/component versions from
  §6.3 step 3, and artifact paths.
- **Statuses:** `pass`, `fail`, `blocked` (a lower tier failed), `skipped (infra)` (VM boot, OS
  update, network, or staging down), `flaky`.
- **Retry:** a failed tier is retried once from a fresh revert. Pass on retry → `flaky`. Fail again →
  `fail`. `infra` failures are not retried more than once per run.
- **Product failure vs infra:** a `fail` means shipped stable is broken on that system and needs
  triage. An `infra` result means the test environment needs fixing. Reports (§9) must keep the
  two visibly apart.
- **Retention:** keep 30 days of results and artifacts on the host.

## 9. Reporting — OPEN

**Undecided. Ask the maintainer before implementing.** Candidates discussed: webhook to a chat
channel, static HTML matrix page, GitHub issue per failing system, email. The result records in §8
are needed regardless of the channel chosen.

## 10. Open questions

| # | Question | Blocks |
|---|---|---|
| Q-1 | Reporting channel(s) (§9). | Implementation start |
| Q-2 | Staging URL, and provisioning of test student and test teacher accounts (no MFA) on the school Keycloak. Who owns them, and does the account lockout policy tolerate nightly logins? | L3 |
| Q-3 | Does the school Keycloak login page work with plain form-post (§6.4), or does it need JavaScript or federate to another IdP? | L3 |
| Q-4 | Host hardware (RAM/disk/CPU) and where it is hosted. | §6.1 |
| Q-5 | Which Windows 11 feature update to pin, and how often to move it. | `windows-11` image |
| Q-6 | Upgrade test (previous stable → current stable via channel): add it to L1? It needs the channels to keep old versions available. | L1 scope |
| Q-7 | Expected Sentinel behavior when the exam ends (exit by itself or keep running), so L3 step 6 can become a pass criterion. | L3 step 6 |
| Q-8 | Staging data hygiene: does `deleteExam` remove sessions and videos, or is extra cleanup needed? | L3 step 9 |

## 11. Decision log (2026-10-04)

| ID | Decision |
|---|---|
| D-1 | Tiered tests: L1 smoke, L2 capture, L3 join + stream, plus a manual tier M. |
| D-2 | Self-hosted libvirt/QEMU VMs, driven by a host systemd timer / cron script (not GitHub Actions). |
| D-3 | Nightly schedule only (no PR or release gating). |
| D-4 | Ubuntu and Debian: oldest + newest supported release (22.04 + 26.04, 12 + 13). |
| D-5 | Nightly installs **public stable** channels only. |
| D-6 | x86_64 only. |
| D-7 | Update the OS before testing, then discard via snapshot revert. |
| D-8 | Linux portable tested on every Linux VM. |
| D-9 | Linux automated sessions: Xorg + lightweight WM, and sway with portal-wlr. GNOME/KDE Wayland stay manual. |
| D-10 | Windows 11 only. Autologon and an interactive-session scheduled task. |
| D-11 | L3 runs against the existing staging server with dedicated test accounts and scripted login. |
| D-12 | L2 via a new hidden `selftest capture` subcommand (S-1). |
| D-13 | Manual tier runs before each stable release. |
| D-14 | Spec location: `sentinel/platform-tests/SPEC.md`. |
| D-15 | Reporting deferred and must be re-asked before implementation (Q-1). |
