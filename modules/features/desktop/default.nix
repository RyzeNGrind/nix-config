{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.features.desktop;
in {
  options.features.desktop = {
    enable = mkEnableOption "Desktop environment features";

    environment = mkOption {
      type = types.enum ["gnome" "kde" "xfce" "i3" "sway"];
      default = "gnome";
      description = "Desktop environment to use";
    };

    extras = {
      office = mkEnableOption "Office applications (LibreOffice)";
      multimedia = mkEnableOption "Multimedia applications (VLC, GIMP)";
      browser = mkOption {
        type = types.enum ["firefox" "chromium" "brave"];
        default = "firefox";
        description = "Default web browser";
      };
    };
  };

  config = mkIf cfg.enable {
    # Desktop environment configuration
    services = {
      xserver = {
        enable = true;
        displayManager.gdm.enable = true;
        desktopManager.gnome.enable = true;
      };
      blueman.enable = true;
      printing = {
        enable = true;
        drivers = with pkgs; [
          gutenprint
          gutenprintBin
          hplip
          hplipWithPlugin
          brlaser
          brgenml1lpr
          brgenml1cupswrapper
        ];
      };
    };

    # Hardware configuration
    hardware = {
      pulseaudio.enable = true;
      bluetooth.enable = true;
      sane = {
        enable = true;
        extraBackends = with pkgs; [
          sane-airscan
          hplipWithPlugin
        ];
      };
    };

    # Environment configuration
    environment = {
      systemPackages = with pkgs; [
        # Desktop utilities
        xdg-utils
        xdg-user-dirs
        # Terminal emulator
        alacritty
        # File manager
        pcmanfm
        # Web browser
        firefox
      ];
    };

    # Enable sound
    sound.enable = true;

    # Enable networking
    networking.networkmanager.enable = true;

    # Enable firmware updates
    services.fwupd.enable = true;

    # Enable power management
    services.power-profiles-daemon.enable = true;
    powerManagement.enable = true;
  };
}
