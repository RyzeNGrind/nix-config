# Feature modules - reusable configuration components
# Following .cursorrules module system guidelines:
# - Single .nix file per feature
# - Atomic and focused responsibility
# - No explicit enable option needed
# - Enabled by default unless disabled
{
  config,
  lib,
  ...
}: {
  imports = [
    ./development.nix # Development tools and environments
    ./gaming.nix # Gaming and GPU passthrough
    ./hardware.nix # Hardware-specific configurations
    ./nix.nix # Nix-specific features
    ./virtualization.nix # Virtualization support
    ./wsl.nix # WSL integration
  ];

  # Feature flag system integration
  options = with lib; {
    features = mkOption {
      type = types.attrsOf types.anything;
      default = {};
      description = "Feature flag system for granular control";
    };
  };

  config = {
    # Ensure features are properly initialized
    features = lib.mkDefault {};
  };
}
