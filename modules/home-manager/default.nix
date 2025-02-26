# Add your reusable home-manager modules to this directory, on their own file (https://nixos.wiki/wiki/Module).
# These should be stuff you would like to share with others, not your personal configurations.
{
  config,
  lib,
  ...
}: {
  imports = [
    ./profiles
    ./wsl.nix
  ];

  options.home-manager = with lib; {
    profiles = mkOption {
      type = types.attrs;
      default = {};
      description = "Home Manager profile configuration";
    };
  };

  config = {
    # Re-export profiles for use in host configurations
    home-manager.profiles = config.profiles;
  };
}
