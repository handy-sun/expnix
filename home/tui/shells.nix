{
  config,
  ...
}:

{
  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh";
  };

  programs.fish = {
    enable = true;
  };

  programs.dotzsh = {
    enable = true;
    enableFishIntegration = true;
    enableFishPrompt = true;
    enableFishGreetingforNix = true;
    enableZshIntegration = true;
  };

  programs.starship = {
    enable = false;
    enableFishIntegration = true;
    enableZshIntegration = true;
    settings = {
      "$schema" = "https://starship.rs/config-schema.json";
      add_newline = false;
      line_break.disabled = true;
      character = {
        success_symbol = "[>](bold green)";
        error_symbol = "[>](bold red)";
      };
      os.symbols = {
        NixOS = " ";
        Macos = " ";
        Debian = " ";
      };
      os.disabled = false;
      format = "\$os\$directory\$character";
      right_format = "\$all";
      # gcloud.disabled = true;
      # aws.disabled = true;
    };
  };
}
