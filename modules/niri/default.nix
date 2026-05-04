{
  inputs,
  pkgs,
  lib,
  ...
}:
let
  baseConfig = pkgs.writeText "niri-base-config.kdl" ''
    include "${pkgs.niri.src}/resources/default-config.kdl"

    include "extra.kdl"
  '';

  noctalia =
    let
      pkg = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
    in
    pkg.overrideAttrs (oldAttrs: {
      nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [
        pkgs.wrapGAppsHook3
      ];
      # https://nixos.org/manual/nixpkgs/stable/#ssec-gnome-common-issues-double-wrapped
      dontWrapGApps = true;
      preFixup = (oldAttrs.preFixup or [ ]) + ''
        qtWrapperArgs+=("''${gappsWrapperArgs[@]}")
      '';
    });

  auto-dark = pkgs.writeShellApplication {
    # place `auto-dark "$1"` in noctalia shell **Theme changed** hook
    name = "auto-dark";
    runtimeInputs = [ pkgs.glib ];
    text = ''
      gsettings set org.gnome.desktop.interface color-scheme "$([ "$1" = true ] && printf 'prefer-dark' || printf 'prefer-light')"

      # needed for some apps like Remmina
      gsettings set org.gnome.desktop.interface gtk-theme "$([ "$1" == true ] && printf 'Adwaita-dark' || printf 'Adwaita')"
      gsettings set org.gnome.desktop.interface icon-theme "$([ "$1" == true ] && printf 'breeze-dark' || printf 'breeze')"
    '';
  };
in
{
  programs.niri.enable = true;

  environment.etc = {
    "niri/config.kdl".source = baseConfig;
    "niri/extra.kdl".source = pkgs.replaceVars ./extra.kdl {
      polkit-kde-agent-1 = pkgs.kdePackages.polkit-kde-agent-1;
    };
  };

  environment.systemPackages = [
    noctalia
    auto-dark
  ]
  ++ (with pkgs; [
    gnome-themes-extra # Adwaita theme
    glib # gsettings
    kdePackages.breeze-icons
  ]);

  hardware.i2c.enable = true;

  # remove buttons on titlebar
  programs.dconf.profiles.user.databases = [
    {
      lockAll = true;
      # settings = {
      #   "org/gnome/desktop/wm/preferences".button-layout = "";
      # };
    }
  ];

  services.gnome.gcr-ssh-agent.enable = false;
}
