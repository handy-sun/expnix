{
  pkgs,
  lib,
  isDarwin,
  ...
}:

let
  isLinux = pkgs.stdenv.isLinux;
in
{
  home.packages =
    with pkgs;
    lib.optionals isLinux [
      strace # a diagnostic, debugging and instructional userspace utility for Linux.
      ltrace # library call monitoring
      pahole
      iotop # io monitoring
      stun
      libtree
      wezterm
      mpv
      fio
      ioping
      hdparm
    ]
    ++ lib.optionals isDarwin [
      xquartz
      ## This is automatically setup on Linux
      gettext
      gnused
    ];
}
