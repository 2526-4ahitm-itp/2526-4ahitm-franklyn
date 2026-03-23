---
title: Installation
description: Install Franklyn Sentinel on your computer
weight: 10
---

## Binaries

You can download the Franklyn Sentinel binaries directly from the [Releases](https://github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/releases).

## Ubuntu

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

## Arch Linux / EndeavourOS

Franklyn Sentinel is available in the AUR as `franklyn-bin`. You can install it using your preferred AUR helper.

Using yay:

```shell
yay -S franklyn-bin
```

Using paru:

```shell
paru -S franklyn-bin
```

<details>
<summary>Development version</summary>

Using yay:

```shell
yay -S franklyn-bin-dev
```

Using paru:

```shell
paru -S franklyn-bin-dev
```

</details>
