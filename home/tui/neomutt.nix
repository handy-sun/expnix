{
  config,
  pkgs,
  lib,
  ...
}:
let
  ## Mail account message, modify it
  mailAddress = "sqzrdev@outlook.com";
  mailRealName = "sqzr";
  gpgKey = "0x9153A88363A54F0D";

  accountSqzr = "account-sqzrdev";
  ## mutt_oauth2.py generate/update token，use gpg
  oauthTokenFile = "${config.xdg.cacheHome}/mutt/oauth-${accountSqzr}";
  mailDir = config.xdg.dataHome + "/mail";

  ## nixpkgs' neomutt don't install contrib/oauth2，package from source
  muttOauth2 = pkgs.writeShellScriptBin "mutt_oauth2.py" ''
    exec ${pkgs.python3}/bin/python3 ${pkgs.neomutt.src}/contrib/oauth2/mutt_oauth2.py "$@"
  '';
in
{
  home.packages = [ muttOauth2 ];

  accounts.email.maildirBasePath = mailDir;

  accounts.email.accounts.${accountSqzr} = {
    primary = true;
    address = mailAddress;
    userName = mailAddress;
    realName = mailRealName;
    ## auto fill imap/smtp host、port、tls（smtp.office365.com:587 + STARTTLS）
    flavor = "outlook.office365.com";

    maildir.path = accountSqzr;

    folders = {
      inbox = "INBOX";
      ## null -> unset record；outlook send
      sent = null;
      drafts = "Drafts";
      trash = "Deleted";
    };

    gpg = {
      key = gpgKey;
      signByDefault = false;
      encryptByDefault = false;
    };

    neomutt = {
      enable = true;
      mailboxType = "maildir";
      ## INBOX by showDefaultMailbox generate，
      extraMailboxes = [
        "Drafts"
        "Sent"
        "Junk"
        "Deleted"
        "Archive"
      ];
      extraConfig = ''
        # MTA：HM's mtaSection only: passwordCommand，xoauth2 
        set smtp_url = "smtp://${mailAddress}@smtp.office365.com:587"
        set smtp_authenticators = "xoauth2"
        set smtp_oauth_refresh_command = "${muttOauth2}/bin/mutt_oauth2.py --decryption-pipe 'gpg --decrypt --pinentry-mode default' ${oauthTokenFile}"
        set ssl_starttls = yes
        set pgp_sign_as = ${gpgKey}
      '';
    };
  };

  ## auto_view text/html depend it
  xdg.configFile."neomutt/mailcap".text = ''
    text/html; ${pkgs.w3m}/bin/w3m -I %{charset} -T text/html; copiousoutput;

    image/*; SWAYSOCK=/dev/null swayimg %s;
    video/*; mpv --loop %s;
    audio/*; mpv --loop --audio-display=no %s;

    application/pdf; zathura %s;
    application/epub+zip; zathura %s;
  '';

  programs.neomutt = {
    enable = true;
    editor = lib.getExe pkgs.neovim;
    sort = "threads";
    ## emits `set mail_check_stats` + interval into each account file
    checkStatsInterval = 60;
    ## every account file head add unmailboxes *，clean sidebar when switch accout
    unmailboxes = true;

    sidebar = {
      enable = true;
      width = 18;
      shortPath = true;
      format = "%B %* [%?N?%N / ?%S]";
    };

    ## plain `set key=value` only; commands belong in extraConfig
    settings = {
      index_format = ''"%3C %Z %[%Y-%m-%d %H:%M] %-12.12L %<l?%4l&%4c> %s"'';
      auto_tag = "yes";
      compose_show_preview = "yes";
      sort_aux = "reverse-last-date-received";
      sidebar_folder_indent = "yes";
      mailcap_path = "${config.xdg.configHome}/neomutt/mailcap";

      ## crypt_use_gpgme is already set by the module
      postpone_encrypt = "yes";
      pgp_self_encrypt = "yes";
      crypt_use_pka = "no";
      crypt_autosign = "no";
      crypt_autoencrypt = "no";
      crypt_autopgp = "yes";
    };

    binds = [
      ## pager
      {
        map = [ "pager" ];
        key = "h";
        action = "exit";
      }
      {
        map = [ "pager" ];
        key = "l";
        action = "view-attachments";
      }
      {
        map = [ "pager" ];
        key = "j";
        action = "next-line";
      }
      {
        map = [ "pager" ];
        key = "k";
        action = "previous-line";
      }
      {
        map = [ "pager" ];
        key = "g";
        action = "top";
      }
      {
        map = [ "pager" ];
        key = "G";
        action = "bottom";
      }
      {
        map = [ "pager" ];
        key = "H";
        action = "display-toggle-weed";
      }

      ## index
      {
        map = [ "index" ];
        key = "j";
        action = "next-entry";
      }
      {
        map = [ "index" ];
        key = "k";
        action = "previous-entry";
      }
      {
        map = [ "index" ];
        key = "l";
        action = "display-message";
      }
      {
        map = [ "index" ];
        key = "/";
        action = "search";
      }
      {
        map = [ "index" ];
        key = "?";
        action = "limit";
      }
      {
        map = [ "index" ];
        key = "d";
        action = "delete-message";
      }
      {
        map = [ "index" ];
        key = "u";
        action = "undelete-message";
      }

      ## attach / alias
      {
        map = [
          "attach"
          "alias"
        ];
        key = "h";
        action = "exit";
      }
      {
        map = [ "attach" ];
        key = "l";
        action = "view-attach";
      }
      {
        map = [
          "attach"
          "index"
        ];
        key = "g";
        action = "first-entry";
      }
      {
        map = [
          "attach"
          "index"
        ];
        key = "G";
        action = "last-entry";
      }

      ## browser
      {
        map = [ "browser" ];
        key = "h";
        action = "goto-parent";
      }
      {
        map = [ "browser" ];
        key = "l";
        action = "descend-directory";
      }
      {
        map = [
          "browser"
          "alias"
        ];
        key = "\\r";
        action = "select-entry";
      }

      ## shared paging
      {
        map = [
          "attach"
          "index"
          "pager"
        ];
        key = "\\CD";
        action = "next-page";
      }
      {
        map = [
          "attach"
          "index"
          "pager"
        ];
        key = "\\CU";
        action = "previous-page";
      }
      {
        map = [
          "attach"
          "index"
          "pager"
        ];
        key = "\\CN";
        action = "half-down";
      }
      {
        map = [
          "attach"
          "index"
          "pager"
        ];
        key = "\\CP";
        action = "half-up";
      }
      {
        map = [
          "attach"
          "index"
          "pager"
        ];
        key = "f";
        action = "flag-message";
      }
      {
        map = [
          "attach"
          "index"
          "pager"
        ];
        key = "F";
        action = "forward-message";
      }
      {
        map = [
          "index"
          "pager"
          "attach"
        ];
        key = "<F1>";
        action = "help";
      }

      ## sidebar
      {
        map = [
          "index"
          "pager"
        ];
        key = "K";
        action = "sidebar-prev";
      }
      {
        map = [
          "index"
          "pager"
        ];
        key = "J";
        action = "sidebar-next";
      }
      {
        map = [
          "index"
          "pager"
        ];
        key = "L";
        action = "sidebar-open";
      }
      {
        map = [
          "index"
          "pager"
        ];
        key = "B";
        action = "sidebar-toggle-visible";
      }
    ];

    macros = [
      {
        map = [
          "index"
          "pager"
        ];
        key = "S";
        action = "<sync-mailbox><enter-command>unset wait_key<enter><shell-escape>$HOME/.local/bin/mbs<enter><enter-command>set wait_key<enter>";
      }
    ];

    ## commands (color/auto_view) have no dedicated options upstream
    extraConfig = ''
      auto_view text/html

      # basic colors
      color error         bold  red       color235
      color tilde               color81   default
      color message             white     color14
      color markers       bold  green     color0
      color attachment    bold  yellow    default
      color search              white     color14
      color status              white     color14
      color indicator           white     color14
      color tree          bold  color9    default

      color index               green     default ~N
      color index               red       default ~D
      color index               yellow    default ~F
      color index               magenta   default ~T

      color index_number        color8    default
      color index_author        color6    default
      color index_size          color7    default
      color index_subject       color6    default

      color sidebar_new         green     default
      color sidebar_flagged     yellow    default

      # message headers
      color hdrdefault          white     default
      color header              white     default     "^(Date)"
      color header              white     color14     "^(Subject)"

      # body
      color body         brightyellow     default "^> \.*"
      color body               yellow     default "^(\t| )*(-|\\*) \.*"

      color quoted             white      default
      color quoted1            white      default
      color quoted2            white      default
      color quoted3            white      default
      color quoted4            white      default
      color signature          white      default

      color bold          bold white      default
      color underline          yellow     default
      color normal             white      default

      color body              yellow      default [\-\.+_a-zA-Z0-9]+@[\-\.a-zA-Z0-9]+
      color body              green       default (https?|ftp)://[\-\.,/%~_:?&=\#a-zA-Z0-9@]+

      # pgp
      color body               red        default    "(BAD signature)"
      color body          bold green      default    "(Good signature)"
      color body          bold green      default    "^gpg: Good signature .*"
      color body          bold color241   default    "^gpg: "
      color body          bold red        default    "^gpg: BAD signature from.*"
      mono  body          bold                       "^gpg: Good signature"
      mono  body          bold                       "^gpg: BAD signature from.*"
    '';
  };
}
