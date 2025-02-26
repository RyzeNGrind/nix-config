# Add your reusable NixOS modules to this directory, on their own file (https://nixos.wiki/wiki/Module).
# These should be stuff you would like to share with others, not your personal configurations.
# NixOS modules - reusable configuration components
{
  # Core system modules
  core = import ../core;

  # Feature modules
  features = import ./features;

  # Profile-specific modules
  profiles = import ./profiles;

  # IDE support modules
  cursor = import ./cursor;
  vscode = import ./vscode;

  # Default module that combines core functionality
  default = {...}: {
    imports = [
      ../core
      ./features
      ./profiles
      ./cursor
      ./vscode
    ];
  };
}
