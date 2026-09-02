{ pkgs, ... }:

{
  programs.gpg.enable = true;

  ## Passphrase cache: pass-encrypted git credential store (GCM credentialStore=gpg)
  ## is decrypted on every git network op; default TTL (600s/7200s) re-prompts constantly.
  ## 1d since last use, 30d hard cap; memory-only, nothing written to disk.
  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry-curses;
    defaultCacheTtl = 86400;
    maxCacheTtl = 2592000;
  };
}
