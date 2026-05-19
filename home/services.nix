_: {
  services = {
    selector4nix = {
      enable = true;
      configureSubstituter = "keep"; # "overwrite" will automatically overwrites the substituter list in $HOME/.config/nix/nix.conf.
      settings = {
        server = {
          ip = "127.0.0.1";
          port = 5496;
        };
        substituters = [
          {
            url = "https://cache.garnix.io/";
            storage_url = "https://garnix-cache.com/";
            priority = 30;
          }
          {
            url = "https://nix-community.cachix.org/";
            priority = 40;
          }
          {
            url = "https://cache.nixos.org/";
            priority = 45;
          }
          {
            url = "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store/";
            priority = 50;
          }
          {
            url = "https://mirror.sjtu.edu.cn/nix-channels/store/";
            priority = 55;
          }
          {
            url = "https://mirrors.ustc.edu.cn/nix-channels/store/";
            priority = 55;
          }
        ];
      };
    };
  };
}
