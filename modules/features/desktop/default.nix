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
    # Basic desktop environment setup
    services.xserver = {
      enable = true;
      displayManager.gdm.enable = cfg.environment == "gnome";
      displayManager.sddm.enable = cfg.environment == "kde";
      desktopManager = {
        gnome.enable = cfg.environment == "gnome";
        plasma5.enable = cfg.environment == "kde";
        xfce.enable = cfg.environment == "xfce";
      };
      windowManager = {
        i3.enable = cfg.environment == "i3";
      };
    };

    # Wayland support
    programs.sway.enable = cfg.environment == "sway";

    # Common desktop packages
    environment.systemPackages = with pkgs; [
      # Basic utilities
      gnome.gnome-terminal
      gnome.nautilus
      gnome.gedit
      gparted
      networkmanagerapplet

      # Selected browser
      (
        if cfg.extras.browser == "firefox"
        then firefox
        else if cfg.extras.browser == "chromium"
        then chromium
        else brave
      )

      # Optional office suite
      (mkIf cfg.extras.office [
        libreoffice-qt
        hunspell
        hunspellDicts.en-us
      ])

      # Optional multimedia applications
      (mkIf cfg.extras.multimedia [
        vlc
        gimp
        inkscape
        audacity
      ])
    ];

    # Enable sound
    sound.enable = true;
    hardware.pulseaudio.enable = true;

    # Enable networking
    networking.networkmanager.enable = true;

    # Enable bluetooth
    hardware.bluetooth.enable = true;
    services.blueman.enable = true;

    # Enable printing
    services.printing = {
      enable = true;
      drivers = [pkgs.gutenprint];
    };

    # Enable scanner support
    hardware.sane = {
      enable = true;
      extraBackends = [pkgs.sane-airscan];
    };

    # Enable firmware updates
    services.fwupd.enable = true;

    # Enable power management
    services.power-profiles-daemon.enable = true;
    powerManagement.enable = true;
  };
}
