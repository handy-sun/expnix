{
  ## Distrust roots affected by the eMudhra intermediate key compromise.
  ## Backport https://github.com/NixOS/nixpkgs/pull/576390 until nixpkgs is updated.
  security.pki.caCertificateBlacklist = [
    "Comodo AAA Services root"
    "emSign ECC Root CA - G3"
    "emSign Root CA - C1"
    "emSign ECC Root CA - C3"
  ];
}
