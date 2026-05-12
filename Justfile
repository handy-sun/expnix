## nix shell nixpkgs#just
set shell := ["bash", "-uc"]

alias s := switch
alias f := nixfmt
alias sh := switch-home

default:
  @just --list

[group('git')]
setup-hook:
  git config core.hooksPath .githooks && chmod +x .githooks/*

# Update the flake inputs about nix and create commit
[group('nix')]
upc-nix:
  nix flake update --commit-lock-file nixpkgs nix-darwin nixos-wsl home-manager rust-overlay noctalia treefmt-nix nixfmt-rs

[group('nix')]
upc-llm:
  nix flake update --commit-lock-file llm-agents

# Update the flake inputs starts with 'my-'
[group('nix')]
upc-my:
  nix flake update --commit-lock-file my-dotzsh my-dotfiles my-dotvim my-nvimdots my-wezterm sbtpl

[group('nix')]
up-my:
  nix flake update my-dotzsh my-dotfiles my-dotvim my-nvimdots my-wezterm sbtpl

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
list-generations:
  sudo nix-env -p /nix/var/nix/profiles/system --list-generations

[group('nix')]
show-conf:
  nix config show

[group('nix')]
switch-home:
  nh home switch .

## Old method to format nix code, which is now replaced by the new formatter based on treefmt-nix
[group('nix')]
nixfmt:
  fd -e nix -X nixfmt

[group('nix')]
nixinfo:
  nix-info -m

[group('nix')]
current-sys:
  readlink /run/current-system

[group('nix')]
query-all pkgname:
  which {{pkgname}} | xargs realpath | xargs nix why-depends --all /run/current-system

## garbage collect all unused nix store entries(system-wide)
[group('nix')]
gc:
  sudo nix-collect-garbage --delete-older-than 4d

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
