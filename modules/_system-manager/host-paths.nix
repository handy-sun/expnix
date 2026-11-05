{
  ...
}:
## Nix-bash login shells start with the compiled-in PATH "/no-such-path", so
## distro /etc/profile.d fragments run without /usr/bin; feed host paths back.
{
  environment.etc."profile.d/00-host-paths.sh".text = ''
    case ":$PATH:" in
      *:/usr/bin:*) ;;
      *) export PATH="$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" ;;
    esac
  '';
}
