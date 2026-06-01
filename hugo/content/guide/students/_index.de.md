---
title: Installation - Schüler
description: Franklyn Sentinel auf deinem Computer installieren
weight: 10
---

## Binärdateien

Du kannst die Franklyn Sentinel Binärdateien direkt von den [Releases](https://github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/releases) herunterladen.

## Ubuntu (24.05+) / Debian (12+)

Füge das Franklyn APT-Repository hinzu, um Franklyn Sentinel zu installieren.

```shell
curl -fsSL https://franklyn.htl-leonding.ac.at/repo/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/franklyn.gpg
echo "deb [signed-by=/etc/apt/keyrings/franklyn.gpg] https://franklyn.htl-leonding.ac.at/repo stable main" | sudo tee /etc/apt/sources.list.d/franklyn.list
sudo apt update
```

Dann kannst du `franklyn-sentinel` installieren.

```shell
sudo apt install franklyn-sentinel
```

<details>
<summary>Entwicklungsversion</summary>

Um stattdessen die Entwicklungsversion zu installieren:

```shell
curl -fsSL https://franklyn.htl-leonding.ac.at/repo/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/franklyn.gpg
echo "deb [signed-by=/etc/apt/keyrings/franklyn.gpg] https://franklyn.htl-leonding.ac.at/repo dev main" | sudo tee /etc/apt/sources.list.d/franklyn.list
sudo apt update
sudo apt install franklyn-sentinel
```

</details>

## nix
Füge dies in deine flake.nix ein:
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

Lade das neueste verfügbare Windows-Portable von unseren [Releases](https://github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/releases) herunter.
Entzippe dann das Verzeichnis und navigiere in einem Terminal dorthin.
```shell
cd Downloads/franklyn-sentinel-[VERSION]-x86_64-windows-portable
```
Du kannst nun franklyn.exe im Terminal ausführen.
```shell
franklyn.exe
```
**Um sicherzustellen, dass Sentinel funktioniert, NICHT auf franklyn.exe doppelklicken – stattdessen ein Terminal öffnen und franklyn.exe ausführen.**
