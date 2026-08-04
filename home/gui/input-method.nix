{
  lib,
  pkgs,
  profileLevel,
  ...
}:

lib.mkIf (profileLevel.guiBase && pkgs.stdenv.isLinux) {
  xdg.configFile."fcitx5/profile" = {
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

      [Groups/0/Items/2]
      Name=pinyin
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
      key_binder/bindings/+:
        - { when: has_menu, accept: Up, send: Page_Up }
        - { when: has_menu, accept: Down, send: Page_Down }
  '';
}
