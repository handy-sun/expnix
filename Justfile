
set shell := ["bash", "-uc"]

alias s := switch
alias e := evtop
alias es := ev-sysmgr
alias f := nixfmt
alias sh := switch-home

sys_conf_root := if os() == "macos" { "darwinConfigurations" } else { "nixosConfigurations" }

nix_inputs := "nixpkgs nix-darwin nixos-wsl home-manager system-manager helix-dev"
my_inputs := "cc-switch-tui my-dotzsh my-dotfiles my-dotvim my-nvimdots my-wezterm my-helix-config sbtpl"

default:
  @just --list

[group('git')]
setup-hook:
  git config core.hooksPath .githooks && chmod +x .githooks/*

# Update the flake inputs about nix and create commit
[group('nix')]
upc-nix:
  nix flake update --commit-lock-file {{nix_inputs}}

# Update the flake inputs starts with 'my-'
[group('nix')]
upc-my:
  nix flake update --commit-lock-file {{my_inputs}}

[group('nix')]
up-my:
  nix flake update {{my_inputs}}

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

# Format nix code using nixfmt
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

# garbage collect all unused nix store entries(system-wide)
[group('nix')]
gc:
  sudo nix-collect-garbage --delete-older-than 4d

# Evaluate the system toplevel derivation for a host
[group('nix')]
evtop host=`hostname`:
  nix eval "$(just --justfile '{{justfile()}}' sys-top-attr '{{host}}')" |& nom

[group('nix')]
ev-sysmgr host="debnsm":
  nix eval "$(just --justfile '{{justfile()}}' sysmgr-top-attr '{{host}}')" |& nom

[group('nix')]
query-depends pkgname host=`hostname`:
  which {{pkgname}} | xargs realpath | xargs nix-store -q --deriver | xargs nix why-depends --derivation "$(just --justfile '{{justfile()}}' sys-top-attr '{{host}}')" 2>/dev/null

[private]
[group('nix')]
sys-top-attr host=`hostname`:
  @printf '%s\n' '.#{{sys_conf_root}}."{{host}}".config.system.build.toplevel'

[private]
[group('nix')]
sysmgr-top-attr host="debnsm":
  @printf '%s\n' '.#systemConfigs."{{host}}".config.build.toplevel'

# Linux
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
query-dep-home pkgname:
  which {{pkgname}} | xargs realpath | xargs nix-store -q --deriver | xargs nix why-depends --derivation .#homeConfigurations.$USER.activationPackage 2>/dev/null

[linux]
[group('nix')]
sysmgr:
  system-manager switch --flake .#debnsm --sudo

# MacOS
[macos]
[group('nix')]
switch:
  nh darwin switch .

[macos]
[group('nix')]
repl-nh:
  nh darwin repl .
