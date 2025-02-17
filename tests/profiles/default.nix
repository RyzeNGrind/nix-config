# Test configuration for profiles
{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ../../modules/profiles
  ];

  # Test development profile
  profiles.development = {
    enable = true;
    ide = "vscodium";
    vscodeRemote = {
      enable = true;
      method = "nix-ld";
    };
    ml = {
      enable = true;
      cudaSupport = true;
      pytorch.enable = true;
    };
  };

  # Test server profile
  profiles.server = {
    enable = true;
    role = "controller";
    monitoring.enable = true;
    backup.enable = true;
    services = ["prometheus" "grafana"];
  };

  # Test that profiles can coexist
  virtualisation = {
    # This should merge correctly from both profiles
    docker = {
      enable = true;
      enableNvidia = true;
      autoPrune.enable = true;
    };
  };

  # Basic system configuration for testing
  boot.isContainer = true;
  users.users.testuser = {
    isNormalUser = true;
    extraGroups = ["wheel" "docker"];
  };
}
