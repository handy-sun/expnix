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
      "speller/algebra/+":
        # 声母模糊音：z/zh、c/ch、s/sh。
        - derive/^([zcs])h/$1/
        - derive/^([zcs])([^h])/$1h$2/
        # 韵母模糊音：an/ang、en/eng、in/ing。
        - derive/ang$/an/
        - derive/an$/ang/
        - derive/eng$/en/
        - derive/en$/eng/
        - derive/in$/ing/
        - derive/ing$/in/
  '';
}
