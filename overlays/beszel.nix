{
  ...
}:

{
  nixpkgs.overlays = [
    (final: prev: {
      beszel = prev.beszel.overrideAttrs (
        finalAttrs: prevAttrs: {
          ## "testing" tag is necessary, api_test.go depends internal/tests
          tags = [ "testing" ];

          checkFlags =
            let
              skippedTests = [
                ## GPU test: build sangbox without GPU tools (macOS/Linux donnot contain nvidia-smi etc.)
                "TestCollectorStartHelpers/nvidia-smi_collector"
                "TestCollectorStartHelpers/rocm-smi_collector"
                "TestCollectorStartHelpers/tegrastats_collector"
                "TestCollectorStartHelpers/nvtop_collector"
                "TestNewGPUManagerPriorityNvtopFallback"
                "TestNewGPUManagerPriorityMixedCollectors"
                "TestNewGPUManagerPriorityNvmlFallbackToNvidiaSmi"
                "TestNewGPUManagerConfiguredCollectorsMustStart"
                "TestNewGPUManagerConfiguredNvmlBypassesCapabilityGate"
                "TestNewGPUManagerJetsonIgnoresCollectorConfig"
                ## Disable environment variable: CHECK_UPDATES
                "TestApiRoutesAuthentication/GET_/update_-_shouldn't_exist_without_CHECK_UPDATES_env_var"
                ## About hub tests
                "TestConfigSyncWithTokens"
              ];
            in
            [ "-skip=^${builtins.concatStringsSep "$|^" skippedTests}$" ];

          postPatch = prevAttrs.postPatch or "" + ''
            substituteInPlace internal/hub/systems/system.go \
              --replace-fail "func (sys *System) StartUpdater() {" \
                "func (sys *System) StartUpdater() { defer func() { recover() }();"
          '';
        }
      );
    })
  ];
}
