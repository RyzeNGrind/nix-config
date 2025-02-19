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
      type = types.enum ["gnome" "kde" "xfce" "i3" "sway" "hyprland"];
      default = "gnome";
      description = "Desktop environment to use";
    };

    hyprland = {
      enable = mkEnableOption "Hyprland desktop environment";
      extraPackages = mkOption {
        type = types.listOf types.package;
        default = [];
        description = "Additional packages to install for Hyprland";
      };
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

  config = mkMerge [
    (mkIf cfg.enable {
      # Desktop environment configuration
      services = {
        xserver = {
          enable = true;
          displayManager.gdm.enable = true;
          desktopManager.gnome.enable = mkIf (cfg.environment == "gnome") true;
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
    })

    # Hyprland-specific configuration
    (mkIf cfg.hyprland.enable {
      programs.hyprland = {
        enable = true;
        xwayland.enable = true;
      };

      environment.systemPackages = with pkgs;
        [
          # Hyprland essentials
          waybar
          wofi
          dunst
          swaylock
          swayidle
          grim
          slurp
          wl-clipboard
          # Additional packages
        ]
        ++ cfg.hyprland.extraPackages;

      # XDG portal for Wayland
      xdg.portal = {
        enable = true;
        wlr.enable = true;
        extraPortals = [pkgs.xdg-desktop-portal-gtk];
      };

      # Enable polkit for privilege escalation
      security.polkit.enable = true;
    })
  ];
}
