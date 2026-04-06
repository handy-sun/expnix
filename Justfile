## nix shell nixpkgs#just
set shell := ["bash", "-uc"]

alias b := build

default:
  @just --list

# Update the flake inputs about nix
[group('nix')]
up-nix:
  nix flake update --commit-lock-file nixpkgs nix-darwin nixos-wsl home-manager

# Update the flake inputs 'my-'
[group('nix')]
up-my:
  nix flake update my-dotzsh my-dotfiles my-dotvim my-nvimdots

# Open a nix shell with the current profile
[group('nix')]
repl:
  nix repl .

# Open a nix shell with the flake
[group('nix')]
repl-flake:
  nix repl -f flake:nixpkgs

[group('nix')]
repl-pkgs:
  nix repl -f '<nixpkgs>'

[group('nix')]
history:
  nix profile history --profile /nix/var/nix/profiles/system

[group('nix')]
preshell:
  nix shell 'nixpkgs#nh' 'nixpkgs#git'

[group('nix')]
show-conf:
  nix config show

[group('nix')]
build-home:
  nh home switch .

## Linux / MacOS
[linux]
[group('nix')]
build:
  nh os switch .

[linux]
[group('nix')]
info:
  nix-info -m

[macos]
[group('nix')]
build:
  nh darwin switch .