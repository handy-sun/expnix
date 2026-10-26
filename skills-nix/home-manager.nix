# Home Manager module body for the expnix skills catalog.
#
# "catalog" is ./catalog.nix, which this flake's apps also read. Targets keep
# agent-skills-nix's defaults for dest, structure (symlink-tree) and
# excludePatterns (["/.system"], so Codex keeps its bundled skills).
{ catalog }:
{
  lib,
  ...
}@args:
let
  ## Only the hosts listed in the catalog get global skill directories. A
  ## standalone Home Manager activation passes no hostName and stays untouched,
  ## so it is read off the argument set instead of being a declared module
  ## argument (a missing declared argument fails evaluation).
  hostName = args.hostName or null;
  enabled = hostName != null && builtins.elem hostName catalog.hosts;
in
{
  programs.agent-skills = lib.mkIf enabled {
    enable = true;

    inherit (catalog) sources skills targets;
  };
}
