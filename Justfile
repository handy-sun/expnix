## nix shell nixpkgs#just
set shell := ["bash", "-uc"]

alias s := switch
alias f := nixfmt

default:
  @just --list

[group('git')]
setup-hook:
  git config core.hooksPath .githooks && chmod +x .githooks/*

# Update the flake inputs about nix and create commit
[group('nix')]
upc-nix:
  nix flake update --commit-lock-file nixpkgs nix-darwin nixos-wsl home-manager rust-overlay

# Update the flake inputs starts with 'my-'
[group('nix')]
upc-my:
  nix flake update --commit-lock-file my-dotzsh my-dotfiles my-dotvim my-nvimdots sbtpl

[group('nix')]
up-my:
  nix flake update my-dotzsh my-dotfiles my-dotvim my-nvimdots sbtpl

# Open a nix repl shell with the current profile
[group('nix')]
repl:
  nix repl .

# Open a nix repl shell with the flake
[group('nix')]
repl-flake:
  nix repl -f flake:nixpkgs

# Open a nix repl shell with the nixpkgs
[group('nix')]
repl-pkgs:
  nix repl -f '<nixpkgs>'

[group('nix')]
history:
  nix profile history --profile /nix/var/nix/profiles/system

[group('nix')]
preshell:
  @grep -q 'experimental-features = nix-command flakes' /etc/nix/nix.conf 2>/dev/null || echo 'experimental-features = nix-command flakes' | sudo tee -a /etc/nix/nix.conf
  nix shell 'nixpkgs#nh' 'nixpkgs#git'

[group('nix')]
show-conf:
  nix config show

[group('nix')]
switch-home:
  nh home switch .

[group('nix')]
nixfmt:
  fd -e nix -X nixfmt

[group('nix')]
nixinfo:
  nix-info -m

[group('nix')]
current-sys:
  readlink /run/current-system

## Linux
[linux]
[group('nix')]
switch:
  nh os switch .

[linux]
[group('nix')]
repl-nh:
  nh os repl .

[linux]
[group('nix')]
query-tree:
  nix-store --gc --print-roots | rg -v '/proc/' | rg -Po '(?<= -> ).*' | xargs -o nix-tree

[linux]
[group('nix')]
query-depends pkgname:
  which {{pkgname}} | xargs realpath | xargs nix-store -q --deriver | xargs nix why-depends --derivation .#nixosConfigurations.$(hostname).config.system.build.toplevel 2>/dev/null

[linux]
[group('nix')]
query-dep-home pkgname:
  which {{pkgname}} | xargs realpath | xargs nix-store -q --deriver | xargs nix why-depends --derivation .#homeConfigurations.$USER.activationPackage 2>/dev/null

## MacOS
[macos]
[group('nix')]
switch:
  nh darwin switch .

[macos]
[group('nix')]
repl-nh:
  nh darwin repl .

[macos]
[group('nix')]
query-depends pkgname:
  which {{pkgname}} | xargs realpath | xargs nix-store -q --deriver | xargs nix why-depends --derivation .#darwinConfigurations.$(hostname).config.system.build.toplevel 2>/dev/null
