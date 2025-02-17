# Profile-based configuration system following ADR-001
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  imports = [
    ./base
    ./wsl
    ./development
    ./gaming
    ./server
  ];

  options.profiles = {
    enable = mkEnableOption "Enable profile system";

    base.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable base profile (always enabled)";
    };

    wsl = {
      enable = mkEnableOption "WSL profile";
      cuda.enable = mkEnableOption "WSL CUDA support";
    };

    development = {
      enable = mkEnableOption "Development profile";
      python.enable = mkEnableOption "Python development";
      rust.enable = mkEnableOption "Rust development";
      nix.enable = mkEnableOption "Nix development";
    };

    gaming.enable = mkEnableOption "Gaming profile";
    server.enable = mkEnableOption "Server profile";
  };

  config = mkMerge [
    {
      # Base profile is always enabled
      assertions = [
        {
          assertion = config.profiles.base.enable;
          message = "Base profile cannot be disabled";
        }
      ];
    }

    (mkIf config.profiles.wsl.enable {
      # WSL-specific assertions
      assertions = [
        {
          assertion = !config.profiles.gaming.enable;
          message = "Gaming profile is not compatible with WSL";
        }
      ];
    })

    (mkIf config.profiles.development.enable {
      # Development profile dependencies
      features.development.enable = true;
      features.shell.enable = true;
    })
  ];
}
