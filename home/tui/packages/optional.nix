## ============================================================
## tuiOptional — nice-to-have extras
## ============================================================
{
  pkgs,
  inputs,
  profileLevel,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  llmAgents = with inputs.llm-agents.packages.${system}; [
    claude-code
    codex
    opencode
    oh-my-opencode
    # gemini-cli
  ];
  helixDev = inputs.helix-dev.packages.${system}.helix;
in
{
  home.packages =
    with pkgs;
    (
      if profileLevel.tuiOptional then
        [
          rust-bin.stable.latest.default
          ## containers
          podman
          docker-buildx # Docker CLI plugin for extended build capabilities with BuildKit
          ## https://github.com/erasin/helix more features more than official helix package
          helixDev
        ]
        ++ llmAgents
      else
        [
          rustc
          cargo
        ]
    );
}
