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
  nix flake update --commit-lock-file nixpkgs nix-darwin nixos-wsl home-manager

# Update the flake inputs starts with 'my-'
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

## Linux / MacOS
[linux]
[group('nix')]
switch:
  nh os switch .

[linux]
[group('nix')]
nixinfo:
  nix-info -m

[macos]
[group('nix')]
switch:
  nh darwin switch .
