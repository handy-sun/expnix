# Home Manager module body for the expnix skills catalog.
#
# "catalog" is ./catalog.nix, which this flake's apps also read. Targets keep
# agent-skills-nix's defaults for dest, structure (symlink-tree) and
# excludePatterns (["/.system"], so Codex keeps its bundled skills).
{ catalog }:
{
  programs.agent-skills = {
    enable = true;

    inherit (catalog) sources skills targets;
  };
}
