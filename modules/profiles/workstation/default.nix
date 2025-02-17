{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.profiles.workstation;
in {
  config = mkIf cfg.enable {
    # Enable required features
    features = {
      desktop = {
        enable = true;
        gnome.enable = true;
      };
    };

    # Common workstation packages
    environment.systemPackages = with pkgs; [
      # System utilities
      htop
      iotop
      powertop
      neofetch

      # File management
      file
      tree
      unzip
      zip

      # Network utilities
      wget
      curl
      dig

      # Text editors
      vim
      nano

      # Development tools
      git
      gnumake
      gcc
    ];

    # Enable common services
    services = {
      # Enable printing
      printing.enable = true;

      # Enable CUPS browsing
      avahi = {
        enable = true;
        nssmdns = true;
      };

      # Enable firmware updates
      fwupd.enable = true;
    };

    # Hardware configuration
    hardware = {
      pulseaudio.enable = true;
      bluetooth.enable = true;
      sane = {
        enable = true;
        extraBackends = [pkgs.sane-airscan];
      };
    };

    # Enable sound
    sound.enable = true;

    # Enable networking
    networking = {
      networkmanager.enable = true;
      firewall = {
        enable = true;
        allowPing = true;
      };
    };

    # Enable power management
    services.power-profiles-daemon.enable = true;
    powerManagement.enable = true;
  };
}
