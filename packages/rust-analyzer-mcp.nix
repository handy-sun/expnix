{
  lib,
  rustPlatform,
  makeWrapper,
  rust-analyzer,
  inputs,
}:

rustPlatform.buildRustPackage {
  pname = "rust-analyzer-mcp";
  version = "0.4.0";

  src = inputs.rust-analyzer-mcp-src;
  cargoHash = "sha256-LcX9VO1ArCdiq5j57JB/Tkfw6pAl6QvckhzMRv5C5dA=";

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
