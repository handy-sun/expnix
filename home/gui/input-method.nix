{
  lib,
  pkgs,
  profileLevel,
  ...
}:

lib.mkIf (profileLevel.guiBase && pkgs.stdenv.isLinux) {
  xdg.configFile."fcitx5/profile" = {
    ## Declaratively own the profile; activation overwrites fcitx5-configtool changes.
    force = true;
    text = ''
      [Groups/0]
      Name=默认
      Default Layout=us
      DefaultIM=rime

      [Groups/0/Items/0]
      Name=keyboard-us
      Layout=

      [Groups/0/Items/1]
      Name=rime
      Layout=

      [GroupOrder]
      0=默认
    '';
  };

  xdg.dataFile."fcitx5/rime/default.custom.yaml".text = ''
    patch:
      __include: rime_ice_suggestion:/
      schema_list:
        - schema: rime_ice
      menu/page_size: 9
      selector/bindings:
        Up: previous_page
        Down: next_page
  '';

  xdg.dataFile."fcitx5/rime/rime_ice.custom.yaml".text = ''
    patch:
      # 中文模式下输入英文时，左右 Shift 都直接上屏原始英文编码并切换到英文。
      "ascii_composer/switch_key/Shift_L": commit_code
      "ascii_composer/switch_key/Shift_R": commit_code
  '';
}
