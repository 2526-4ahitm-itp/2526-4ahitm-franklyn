---
title: Installation
description: Install Franklyn Sentinel on your computer
weight: 10
---

## Quick Install (Linux)

> **Requires glibc 2.34+.** See [Linux (Portable)](#linux-portable) for supported distributions.

Installs into your home directory. No `sudo` required.

```shell
curl -fsSL https://franklyn.htl-leonding.ac.at/scripts/sentinel-install.sh | bash
```

Run the same command again to **update**.

To **uninstall** run:

```shell
curl -fsSL https://franklyn.htl-leonding.ac.at/scripts/sentinel-install.sh | bash -s -- --uninstall
```

## Linux (Portable)

> **Minimum requirements (glibc 2.34+):** Ubuntu 22.04 (Jammy Jellyfish), Debian 12 (Bookworm), Fedora 35, RHEL / Rocky / AlmaLinux 9, openSUSE Leap 15.6 / Tumbleweed, Arch Linux.
> Wayland screen capture additionally requires PipeWire installed on the host.

Download the portable bundle for your architecture from [Releases](https://github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/releases). The archive bundles all runtime libraries — no system dependencies required beyond glibc.

Extract and run:

```shell
tar --zstd -xf franklyn-sentinel-[VERSION]-[ARCH]-portable.tar.zst
cd franklyn-sentinel-[VERSION]-[ARCH]-portable
./bin/franklyn
```

## Ubuntu (22.04+) / Debian (12+)

Add the Franklyn APT repository to install Franklyn Sentinel.

```shell
curl -fsSL https://franklyn.htl-leonding.ac.at/repo/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/franklyn.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/franklyn.gpg] https://franklyn.htl-leonding.ac.at/repo stable main" | sudo tee /etc/apt/sources.list.d/franklyn.list
sudo apt update
```

Then you can install `franklyn-sentinel`.

```shell
sudo apt install franklyn-sentinel
```

<details>
<summary>Development version</summary>

To install the development version instead:

```shell
curl -fsSL https://franklyn.htl-leonding.ac.at/repo/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/franklyn.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/franklyn.gpg] https://franklyn.htl-leonding.ac.at/repo dev main" | sudo tee /etc/apt/sources.list.d/franklyn.list
sudo apt update
sudo apt install franklyn-sentinel
```

</details>

## Arch Linux (AUR)

Franklyn Sentinel is available in the [AUR](https://aur.archlinux.org/packages/franklyn-bin) as `franklyn-bin`. Install it with an AUR helper such as `yay` or `paru`:

```shell
yay -S franklyn-bin
```

## openSUSE Tumbleweed

> openSUSE Leap is not supported via this method.

Install Franklyn Sentinel via the [openSUSE Open Build Service](https://software.opensuse.org/download.html?project=home%3Afranklyn&package=franklyn).

Add the repository and install the package:

```shell
sudo zypper addrepo https://download.opensuse.org/repositories/home:franklyn/openSUSE_Tumbleweed/home:franklyn.repo
sudo zypper refresh
sudo zypper install franklyn
```

## Fedora (43+)

Install Franklyn Sentinel from the Franklyn repository on the [openSUSE Open Build Service](https://software.opensuse.org/download.html?project=home%3Afranklyn&package=franklyn).

Add the repository and install the package:

```shell
sudo dnf config-manager addrepo --from-repofile=https://franklyn.htl-leonding.ac.at/fedora/franklyn.repo
sudo dnf install franklyn
```

## Nix

Franklyn Sentinel is available as a Nix flake package (`franklyn-sentinel`).

### Binary Cache (Cachix)

Add the Franklyn Cachix cache to avoid rebuilding from source.

**NixOS** — add to your configuration:

```nix
nix.settings = {
  substituters = [ "https://franklyn.cachix.org" ];
  trusted-public-keys = [
    "franklyn.cachix.org-1:rvchIepdAmB8uOOc1dA7rxhncnDB0LfrFrYb+BhiA4M="
  ];
};
```

**Non-NixOS** — add to `/etc/nix/nix.conf` or `~/.config/nix/nix.conf`:

```
substituters = https://cache.nixos.org https://franklyn.cachix.org
trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= franklyn.cachix.org-1:rvchIepdAmB8uOOc1dA7rxhncnDB0LfrFrYb+BhiA4M=
```

Or install `cachix` and run:

```shell
cachix use franklyn
```

### NixOS (flakes)

Add the Franklyn flake input to your `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    franklyn = {
      url = "github:2526-4ahitm-itp/2526-4ahitm-franklyn";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ...
  };

  outputs = { nixpkgs, franklyn, ... }: {
    nixosConfigurations.your-host = nixpkgs.lib.nixosSystem {
      modules = [
        {
          environment.systemPackages = [
            franklyn.packages.${system}.franklyn-sentinel
          ];
        }
      ];
    };
  };
}
```

### Home Manager

Add to your Home Manager configuration:

```nix
{ inputs, pkgs, system, ... }: {
  home.packages = [
    inputs.franklyn.packages.${system}.franklyn-sentinel
  ];
}
```

### Without NixOS (nix profile)

Install into your user profile with:

```shell
nix profile install github:2526-4ahitm-itp/2526-4ahitm-franklyn#franklyn-sentinel
```

### Run without installing

```shell
nix run github:2526-4ahitm-itp/2526-4ahitm-franklyn#franklyn-sentinel -c franklyn
```



## macOS

> **Requires a Mac with Apple Silicon (M1 or newer) and macOS 14 (Sonoma) or newer.** Intel Macs are not supported yet.

Open **Terminal** and run the same installer as on Linux. It installs into your home directory, no `sudo` required:

```shell
curl -fsSL https://franklyn.htl-leonding.ac.at/scripts/sentinel-install.sh | bash
```

Open a new terminal window afterwards so `franklyn` is on your `PATH`. Updating and uninstalling work exactly like in the [Quick Install](#quick-install-linux).

### Screen Recording permission

The first time you run `franklyn join <pin>`, macOS asks whether your terminal app may record the screen:

1. Click **Open System Settings** and turn on your terminal app (e.g. **Terminal**) under **Privacy & Security → Screen & System Audio Recording**.
2. Let macOS **Quit & Reopen** the terminal.
3. Run `franklyn join <pin>` again.

The permission belongs to the terminal app, so you only grant it once — updates keep it. A different terminal app (e.g. iTerm) needs its own permission.

### Manual download

{{< callout type="warning" >}}
Prefer the installer above. macOS refuses to start this build when it was downloaded with a web browser, until you remove the download mark as shown below.
{{< /callout >}}

Download `franklyn-sentinel-[VERSION]-aarch64-darwin-portable.tar.gz` from our [Releases](https://github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/releases), then extract it outside of `Downloads` and remove the browser's download mark:

```shell
cd ~
mkdir franklyn-sentinel
tar -xzf ~/Downloads/franklyn-sentinel-*-aarch64-darwin-portable.tar.gz -C franklyn-sentinel
xattr -dr com.apple.quarantine franklyn-sentinel
./franklyn-sentinel/bin/franklyn join <pin>
```

## Windows


Download the newest available windows portable from our [Releases](https://github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/releases).
Then unzip the directory and navigate to it in a terminal.

```shell
cd Downloads/franklyn-sentinel-[VERSION]-x86_64-windows-portable
```

{{< callout type="warning" >}}
Do **not** double-click `franklyn.exe`. Open a terminal and run `franklyn.exe` from there — sentinel requires a terminal to function correctly.
{{< /callout >}}

You can now execute franklyn.exe in the terminal.

```shell
franklyn.exe join <pin>
```
