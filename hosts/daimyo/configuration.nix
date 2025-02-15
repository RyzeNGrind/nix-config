# Host-specific configuration for daimyo
{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    # Import base configurations
    ../base/default.nix
    ../base/wsl.nix
  ];

  # Machine-specific settings
  networking.hostName = "daimyo";
  time.timeZone = "America/Toronto";
  i18n.defaultLocale = "en_CA.UTF-8";

  # Additional packages
  environment.systemPackages = with pkgs; [
    # Development tools
    git-lfs
    gh
    direnv
    nixfmt
    alejandra
    statix

    # System tools
    htop
    iotop
    neofetch
    pre-commit
  ];

  # User configuration
  users.users.ryzengrind = {
    isNormalUser = true;
    extraGroups = ["wheel" "docker" "networkmanager"];
    hashedPassword = "$6$VOP1Yx5OUXwpOFaG$tVWf3Ai0.kzXpblhnatoeHHZb1xGKUuSEEQO79y1efrSyXR0sGmvFjo7oHbZBuQgZ3NFZi0MahU5hbyzsIwqq.";
  };

  # Testing configuration
  testing.suites.host = {
    enable = true;
    description = "Host-specific configuration tests";
    script = ''
      import pytest
      from nixostest import Machine

      def test_base_config(machine: Machine) -> None:
          """Test base configuration."""
          machine.succeed("test -f /etc/nixos/configuration.nix")
          machine.succeed("test -d /nix/store")

      def test_user_setup(machine: Machine) -> None:
          """Test user configuration."""
          machine.succeed("id ryzengrind")
          machine.succeed("groups ryzengrind | grep -q wheel")

      def test_packages(machine: Machine) -> None:
          """Test installed packages."""
          for pkg in ["git", "direnv", "htop"]:
              machine.succeed(f"type -P {pkg}")

      def test_locale(machine: Machine) -> None:
          """Test locale settings."""
          machine.succeed("locale | grep -q 'en_CA.UTF-8'")
          machine.succeed("timedatectl show | grep -q 'America/Toronto'")
    '';
  };
}
