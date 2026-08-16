{
  lib,
  rustPlatform,
  makeWrapper,
  rust-analyzer,
  inputs,
}:

rustPlatform.buildRustPackage {
  pname = "rust-analyzer-mcp";
  version = "0.2.0-unstable-2026-08-15";

  src = inputs.rust-analyzer-mcp-src;
  cargoHash = "sha256-7t4bjyCcbxFAO/29re7cjoW1ACieeEaM4+QT5QAwc34=";

  # Upstream integration tests depend on test-only rust-analyzer behavior
  # that is unavailable in the Nix sandbox.
  doCheck = false;

  nativeBuildInputs = [ makeWrapper ];

  postFixup = ''
    wrapProgram $out/bin/rust-analyzer-mcp \
      --prefix PATH : ${lib.makeBinPath [ rust-analyzer ]}
  '';

  meta = {
    description = "MCP server for rust-analyzer";
    homepage = "https://github.com/zeenix/rust-analyzer-mcp";
    license = lib.licenses.mit;
    mainProgram = "rust-analyzer-mcp";
  };
}
