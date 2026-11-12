{
  ...
}:

{
  nixpkgs.overlays = [
    (final: prev: {
      ## Both skipped cases are Linux-only, so leave the darwin derivation
      ## untouched: the stock one is binary-cached, ours would not be.
      netwatch =
        if prev.stdenv.hostPlatform.isLinux then
          prev.netwatch.overrideAttrs (old: {
            ## The 0.39.0 suite has two cases that depend on the host kernel and
            ## on /proc visibility inside the build sandbox: the Landlock parser
            ## test expects MSG_FASTOPEN to survive the sandbox (Linux 7.x answers
            ## EACCES) and the ss-fallback test expects its UDP socket in
            ## /proc/net/udp.
            checkFlags = (old.checkFlags or [ ]) ++ [
              "--skip"
              "sandbox::linux::tests::parser_layer_leaves_fast_open_and_autobind_open"
              "--skip"
              "collectors::connections::tests::failing_ss_falls_back_to_proc_net"
            ];
          })
        else
          prev.netwatch;
    })
  ];
}
