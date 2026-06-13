---
title: Installation
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

## openSUSE Tumbleweed

Installiere Franklyn Sentinel über den [openSUSE Open Build Service](https://software.opensuse.org/download.html?project=home%3Afranklyn&package=franklyn).

Füge das Repository hinzu und installiere das Paket:

```shell
sudo zypper addrepo https://download.opensuse.org/repositories/home:franklyn/openSUSE_Tumbleweed/home:franklyn.repo
sudo zypper refresh
sudo zypper install franklyn
```

## Nix

Franklyn Sentinel ist als Nix-Flake-Paket (`franklyn-sentinel`) verfügbar.

### Binary Cache (Cachix)

Füge den Franklyn Cachix-Cache hinzu, um das Bauen aus dem Quellcode zu vermeiden.

**NixOS** — füge folgendes zu deiner Konfiguration hinzu:

```nix
nix.settings = {
  substituters = [ "https://franklyn.cachix.org" ];
  trusted-public-keys = [
    "franklyn.cachix.org-1:rvchIepdAmB8uOOc1dA7rxhncnDB0LfrFrYb+BhiA4M="
  ];
};
```

**Ohne NixOS** — füge folgendes zu `/etc/nix/nix.conf` oder `~/.config/nix/nix.conf` hinzu:

```
substituters = https://cache.nixos.org https://franklyn.cachix.org
trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= franklyn.cachix.org-1:rvchIepdAmB8uOOc1dA7rxhncnDB0LfrFrYb+BhiA4M=
```

Oder installiere `cachix` und führe folgendes aus:

```shell
cachix use franklyn
```

### NixOS (Flakes)

Füge den Franklyn-Flake-Input zu deiner `flake.nix` hinzu:

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

Füge folgendes zu deiner Home Manager-Konfiguration hinzu:

```nix
{ inputs, pkgs, system, ... }: {
  home.packages = [
    inputs.franklyn.packages.${system}.franklyn-sentinel
  ];
}
```

### Ohne NixOS (nix profile)

In dein Benutzerprofil installieren:

```shell
nix profile install github:2526-4ahitm-itp/2526-4ahitm-franklyn#franklyn-sentinel
```

### Ohne Installation ausführen

```shell
nix run github:2526-4ahitm-itp/2526-4ahitm-franklyn#franklyn-sentinel
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
