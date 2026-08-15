{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.mihomo;
  subscriptionCredential = "mihomo-subscription-url";
  runtimeConfig = "/run/mihomo/config.yaml";
  execStart = lib.concatStringsSep " " (
    [
      (lib.getExe cfg.package)
      "-d /var/lib/private/mihomo"
      "-f ${runtimeConfig}"
    ]
    ++ lib.optional (cfg.webui != null) "-ext-ui ${lib.escapeShellArg cfg.webui}"
    ++ lib.optional (cfg.extraOpts != null) cfg.extraOpts
  );
  prepareConfig = pkgs.writeShellScript "mihomo-prepare-config" ''
    set -euo pipefail
    umask 077

    credential_file="$CREDENTIALS_DIRECTORY/${subscriptionCredential}"
    subscription_url="$(<"$credential_file")"
    case "$subscription_url" in
      http://*|https://*) ;;
      *)
        echo "Error: Mihomo subscription URL must use http or https" >&2
        exit 1
        ;;
    esac

    candidate_file="$(${lib.getExe' pkgs.coreutils "mktemp"} "$RUNTIME_DIRECTORY/.config.yaml.XXXXXX")"
    trap '${lib.getExe' pkgs.coreutils "rm"} -f -- "$candidate_file"' EXIT

    ${lib.getExe pkgs.wget} \
      --quiet \
      --timeout 15 \
      --tries 3 \
      --output-document "$candidate_file" \
      --input-file "$credential_file"
    test -s "$candidate_file"
    ${lib.getExe cfg.package} \
      -d "$STATE_DIRECTORY" \
      -t \
      -f "$candidate_file"
    ${lib.getExe' pkgs.coreutils "mv"} -- "$candidate_file" "$RUNTIME_DIRECTORY/config.yaml"
  '';
in
{
  options.services.mihomo.subscriptionUrlFile = lib.mkOption {
    type = lib.types.nullOr lib.types.path;
    default = null;
    description = ''
      Path to a file containing a complete Mihomo configuration subscription URL.
      When set, download and validate the configuration before every service start.
    '';
  };

  config = lib.mkIf (cfg.enable && cfg.subscriptionUrlFile != null) {
    services.mihomo.configFile = lib.mkDefault cfg.subscriptionUrlFile;

    systemd.services.mihomo.serviceConfig = {
      RuntimeDirectory = "mihomo";
      RuntimeDirectoryMode = "0700";
      LoadCredential = lib.mkForce [
        "${subscriptionCredential}:${cfg.subscriptionUrlFile}"
      ];
      ExecStartPre = prepareConfig;
      ExecStart = lib.mkForce execStart;
    };
  };
}
