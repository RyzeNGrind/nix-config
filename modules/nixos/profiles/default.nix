# Profile modules - reusable configuration components
# Following ADR-001 profile-based configuration and .cursorrules guidelines
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.profiles;
in {
  imports = [
    ./dev.nix # Development environment profile
    ./desktop.nix # Desktop environment profile
    ./security.nix # Security and hardening profile
    ./gaming.nix # Gaming environment profile
    ./srv.nix # Server environment profile
  ];

  options.profiles = with lib; {
    enable = mkEnableOption "Profile-based configuration system";

    # Profile categories are defined in their respective modules
    # This is just the top-level enable option
  };

  config = lib.mkIf cfg.enable {
    # Base configuration for all profiles
    environment.systemPackages = with pkgs; [
      git
      curl
      wget
      vim
    ];

    # Profile-specific configurations are handled in their respective modules
  };
}
