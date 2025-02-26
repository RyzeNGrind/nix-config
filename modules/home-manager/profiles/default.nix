# Home Manager profile modules - reusable configuration components
{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./development.nix
    ./shell.nix
    ./desktop.nix
  ];

  options = with lib; {
    profiles = {
      enable = mkEnableOption "Profile-based configuration system";

      development = {
        enable = mkEnableOption "Development environment profile";
        ide = {
          enable = mkEnableOption "IDE support";
          vscode.enable = mkEnableOption "VSCode IDE";
          cursor.enable = mkEnableOption "Cursor IDE";
        };
      };

      shell = {
        enable = mkEnableOption "Shell environment profile";
        tmux.enable = mkEnableOption "Tmux terminal multiplexer";
        fish = {
          enable = mkEnableOption "Fish shell";
          default = mkEnableOption "Use fish as default shell";
        };
        bash = {
          enable = mkEnableOption "Bash shell";
          default = mkEnableOption "Use bash as default shell";
          enableCompletion = mkEnableOption "Enable bash completion";
        };
      };

      desktop = {
        enable = mkEnableOption "Desktop environment profile";
        apps = {
          browsers.enable = mkEnableOption "Web browsers";
          communication.enable = mkEnableOption "Communication tools";
        };
      };
    };
  };

  config = lib.mkIf config.profiles.enable {
    # Base configuration for all profiles
    home.packages = with pkgs; [
      git
      curl
      wget
      vim
    ];

    # Profile-specific configurations are handled in their respective modules
  };
}
