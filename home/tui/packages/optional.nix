## ============================================================
## tuiOptional — nice-to-have extras
## ============================================================
{
  pkgs,
  profileLevel,
  ...
}:

{
  home.packages =
    with pkgs;
    (
      if profileLevel.tuiOptional then
        [ rust-bin.stable.latest.default ]
      else
        [
          rustc
          cargo
        ]
    );
}
