
set shell := ["bash", "-uc"]

alias s := switch
alias f := nixfmt
alias sh := switch-home

sys_conf_root := if os() == "macos" { "darwinConfigurations" } else { "nixosConfigurations" }

default:
  @just --list

[group('git')]
setup-hook:
  git config core.hooksPath .githooks && chmod +x .githooks/*

# Update the flake inputs about nix and create commit
[group('nix')]
upc-nix:
  nix flake update --commit-lock-file nixpkgs nix-darwin nixos-wsl home-manager system-manager helix-dev

# Update the flake inputs starts with 'my-'
[group('nix')]
upc-my:
  nix flake update --commit-lock-file cc-switch-tui my-dotzsh my-dotfiles my-dotvim my-nvimdots my-wezterm my-helix-config my-superc sbtpl

[group('nix')]
up-my:
  nix flake update cc-switch-tui my-dotzsh my-dotfiles my-dotvim my-nvimdots my-wezterm my-helix-config my-superc sbtpl

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

[private]
[group('nix')]
sys-top-attr host=`hostname`:
  @printf '%s\n' '.#{{sys_conf_root}}."{{host}}".config.system.build.toplevel'

[group('nix')]
query-all pkgname:
  which {{pkgname}} | xargs realpath | xargs nix why-depends --all /run/current-system

# garbage collect all unused nix store entries(system-wide)
[group('nix')]
gc:
  sudo nix-collect-garbage --delete-older-than 4d

# Linux
[linux]
[group('nix')]
switch:
  if [ "$(hostname)" = "reinsvps" ]; then \
    test -e /etc/nixos/private/reinsvps-network.nix || { \
      printf '%s\n' "missing /etc/nixos/private/reinsvps-network.nix"; \
      exit 1; \
    }; \
    nh os switch --impure .; \
  else \
    nh os switch .; \
  fi

[linux]
[group('nix')]
repl-nh:
  nh os repl .

[linux]
[group('nix')]
query-tree:
  nix-store --gc --print-roots | rg -v '/proc/' | rg -Po '(?<= -> ).*' | xargs -o nix-tree

# Evaluate the system toplevel derivation for a host
[group('nix')]
evtop host=`hostname`:
  if [ "{{host}}" = "reinsvps" ] && [ "$(hostname)" = "reinsvps" ]; then \
    test -e /etc/nixos/private/reinsvps-network.nix || { \
      printf '%s\n' "missing /etc/nixos/private/reinsvps-network.nix"; \
      exit 1; \
    }; \
    nix eval --impure "$(just --justfile '{{justfile()}}' sys-top-attr '{{host}}')"; \
  else \
    nix eval "$(just --justfile '{{justfile()}}' sys-top-attr '{{host}}')"; \
  fi

[group('nix')]
query-depends pkgname host=`hostname`:
  which {{pkgname}} | xargs realpath | xargs nix-store -q --deriver | xargs nix why-depends --derivation "$(just --justfile '{{justfile()}}' sys-top-attr '{{host}}')" 2>/dev/null

[linux]
[group('nix')]
query-dep-home pkgname:
  which {{pkgname}} | xargs realpath | xargs nix-store -q --deriver | xargs nix why-depends --derivation .#homeConfigurations.$USER.activationPackage 2>/dev/null

[linux]
[group('nix')]
sysmgr:
  system-manager switch --flake .#$(hostname) --sudo

# MacOS
[macos]
[group('nix')]
switch:
  nh darwin switch .

[macos]
[group('nix')]
repl-nh:
  nh darwin repl .
