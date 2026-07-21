{
  lib,
  python3Packages,
  makeWrapper,
  git,
  inputs,
}:

python3Packages.buildPythonApplication {
  pname = "qt-rules-mcp";
  version = "0.1.0-unstable";
  pyproject = true;

  src = inputs.qt-rules-mcp-src;

  build-system = [ python3Packages.setuptools ];
  dependencies = with python3Packages; [
    fastmcp
    gitpython
  ];

  nativeBuildInputs = [ makeWrapper ];

  # GitPython invokes the git executable to clone and refresh QT-Rules.
  postFixup = ''
    wrapProgram $out/bin/qt-rules-mcp \
      --prefix PATH : ${lib.makeBinPath [ git ]}
  '';

  meta = {
    description = "MCP server for Qt AI rules";
    homepage = "https://github.com/lpmwfx/QT-RulesMCP";
    license = lib.licenses.eupl12;
    mainProgram = "qt-rules-mcp";
  };
}
