---
title: Installation - Student
description: Install Franklyn Sentinel on your computer
weight: 10
---

## Binaries

You can download the Franklyn Sentinel binaries directly from the [Releases](https://github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/releases).

## Ubuntu (24.05+) / Debian (12+)

Add the Franklyn APT repository to install Franklyn Sentinel.

```shell
curl -fsSL https://franklyn.htl-leonding.ac.at/repo/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/franklyn.gpg
echo "deb [signed-by=/etc/apt/keyrings/franklyn.gpg] https://franklyn.htl-leonding.ac.at/repo stable main" | sudo tee /etc/apt/sources.list.d/franklyn.list
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
echo "deb [signed-by=/etc/apt/keyrings/franklyn.gpg] https://franklyn.htl-leonding.ac.at/repo dev main" | sudo tee /etc/apt/sources.list.d/franklyn.list
sudo apt update
sudo apt install franklyn-sentinel
```

</details>

## nix
put this into your flake.nix:
```
{
  inputs = {

    franklyn = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ...
  }
}


# anwenden in nixos
environment.systemPackages = [
	inputs.franklyn.packages.${system}.franklyn-sentinel
]
```



## Windows

Download the newest available windows portable from our [Releases](https://github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/releases).
Then unzip the directory and navigate to it in a terminal.
```shell
cd Downloads/franklyn-sentinel-[VERSION]-x86_64-windows-portable
```
You can now execute franklyn.exe in the terminal.
```shell
franklyn.exe
```
**To ensure sentinel works, DO NOT double-click franklyn.exe, instead open a terminal and execute franklyn.exe**