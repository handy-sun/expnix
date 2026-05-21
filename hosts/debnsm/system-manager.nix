{
  pkgs,
  ...
}:

{
  services.beszel.agent = {
    enable = true;
    environmentFile = "/etc/beszel-agent.env";
  };

  environment.systemPackages = with pkgs; [
    curl
    wget
    file
    fish
    zsh
    docker
    zerotierone
    zstd
    zip
    unzip
    xz
    nginx
    strace
    lsof
    procps
    fakeroot
    cron
  ];
}
