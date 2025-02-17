# Program configurations following ADR-004 and module system guidelines
{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    # Features - Single responsibility, enabled by default
    ./features/shell-integration.nix
    ./features/development-tools.nix
    ./features/system-utils.nix

    # Bundles - Groups of related features, explicit enabling required
    ./bundles/development.nix
    ./bundles/desktop.nix
    ./bundles/server.nix

    # Services - Service-specific configurations, explicit enabling required
    ./services/1password.nix
    ./services/hyprland.nix
    ./services/docker.nix

    # Custom extensions and wrappers
    ./custom-scripts
    ./development
    ./system-utils
  ];

  meta = {
    description = "Program configurations following ADR-004 specialisation patterns";
    maintainers = ["ryzengrind"];
  };
}
