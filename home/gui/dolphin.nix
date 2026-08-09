{
  config,
  lib,
  pkgs,
  profileLevel,
  ...
}:
let
  dolphinConfig = config.xdg.configHome + "/dolphinrc";
  dolphinPlaces = config.xdg.dataHome + "/user-places.xbel";
  openListUrl = "file:///mnt/opls";
  kwriteconfig = lib.getExe' pkgs.kdePackages.kconfig "kwriteconfig6";
  openListPlaceText = ''
    <bookmark href="${openListUrl}">
     <title>OpenList · fngo WebDAV</title>
     <info>
      <metadata owner="http://freedesktop.org">
       <bookmark:icon name="folder-network"/>
      </metadata>
      <metadata owner="http://www.kde.org">
       <ID>expnix/openlist-fngo</ID>
      </metadata>
     </info>
    </bookmark>
  '';
  openListPlace = pkgs.writeText "dolphin-openlist-place.xbel" openListPlaceText;
  ## Seed version 0 so KFilePlacesModel adds the current standard locations on first launch.
  initialPlaces = pkgs.writeText "dolphin-initial-places.xbel" ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE xbel>
    <xbel xmlns:bookmark="http://www.freedesktop.org/standards/desktop-bookmarks" xmlns:kdepriv="http://www.kde.org/kdepriv" xmlns:mime="http://www.freedesktop.org/standards/shared-mime-info">
     <info>
      <metadata owner="http://www.kde.org">
       <kde_places_version>0</kde_places_version>
       <GroupState-Places-IsHidden>false</GroupState-Places-IsHidden>
       <GroupState-Remote-IsHidden>false</GroupState-Remote-IsHidden>
       <GroupState-Devices-IsHidden>false</GroupState-Devices-IsHidden>
       <GroupState-RemovableDevices-IsHidden>false</GroupState-RemovableDevices-IsHidden>
       <GroupState-Tags-IsHidden>false</GroupState-Tags-IsHidden>
      </metadata>
     </info>
     ${openListPlaceText}
    </xbel>
  '';
in
lib.mkIf (profileLevel.guiBase && pkgs.stdenv.isLinux) {
  home.activation = {
    ## Seed Dolphin 26.04.3 defaults only when dolphinrc does not exist.
    ## Keep dolphinrc mutable so later UI changes and migrations remain writable.
    configureDolphin = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [[ ! -e ${lib.escapeShellArg dolphinConfig} ]]; then
        $DRY_RUN_CMD ${kwriteconfig} --file ${lib.escapeShellArg dolphinConfig} --group General --key Version 200
        $DRY_RUN_CMD ${kwriteconfig} --file ${lib.escapeShellArg dolphinConfig} --group InformationPanel --key previewsShown true
        $DRY_RUN_CMD ${kwriteconfig} --file ${lib.escapeShellArg dolphinConfig} --group InformationPanel --key previewsAutoPlay false
      fi
    '';

    configureDolphinPlaces = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [[ ! -e ${lib.escapeShellArg dolphinPlaces} ]]; then
        $DRY_RUN_CMD ${lib.getExe' pkgs.coreutils "install"} -Dm600 ${initialPlaces} ${lib.escapeShellArg dolphinPlaces}
      elif ! ${lib.getExe pkgs.gnugrep} -Fq ${lib.escapeShellArg openListUrl} ${lib.escapeShellArg dolphinPlaces}; then
        $DRY_RUN_CMD env DOLPHIN_PLACE_SNIPPET=${openListPlace} ${lib.getExe pkgs.perl} -0pi -e '
          BEGIN {
            local $/;
            open my $snippet_file, "<", $ENV{DOLPHIN_PLACE_SNIPPET} or die $!;
            $place = <$snippet_file>;
          }
          s{</xbel>}{$place\n</xbel>} or die "Invalid user-places.xbel: missing closing xbel element\n";
        ' ${lib.escapeShellArg dolphinPlaces}
      fi
    '';
  };
}
