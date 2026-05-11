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
  llmAgents = with inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}; [
    claude-code
    codex
    opencode
    oh-my-opencode
    # gemini-cli
  ];
in
{
  home.packages =
    with pkgs;
    (
      if profileLevel.tuiOptional then
        [ rust-bin.stable.latest.default ] ++ llmAgents
      else
        [
          rustc
          cargo
        ]
    );
}
