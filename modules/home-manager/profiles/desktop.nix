# Desktop environment profile
{pkgs, ...}: {
  home.packages = with pkgs; [
    # GUI Applications
    firefox
    chromium
    vlc
    gimp

    # Communication
    slack
    discord
    zoom-us

    # File Management
    pcmanfm
    gnome.file-roller

    # System Utilities
    pavucontrol
    blueman

    # Fonts
    (nerdfonts.override {fonts = ["FiraCode" "DroidSansMono"];})
  ];

  # GTK Theme
  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome.gnome-themes-extra;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    font = {
      name = "Sans";
      size = 10;
    };
  };

  # Qt Theme
  qt = {
    enable = true;
    platformTheme = {
      name = "gtk";
    };
    style = {
      name = "adwaita-dark";
      package = pkgs.adwaita-qt;
    };
  };

  # Cursor Theme
  home.pointerCursor = {
    name = "Adwaita";
    package = pkgs.gnome.adwaita-icon-theme;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  # Desktop Services
  services = {
    # Screen color temperature
    redshift = {
      enable = true;
      latitude = "40.7"; # Adjust to your location
      longitude = "-74.0"; # Adjust to your location
      temperature = {
        day = 6500;
        night = 3700;
      };
    };

    # Notification daemon
    dunst = {
      enable = true;
      settings = {
        global = {
          font = "FiraCode Nerd Font 10";
          frame_width = 2;
          frame_color = "#8AADF4";
          separator_color = "frame";
          corner_radius = 8;
        };
        urgency_low = {
          background = "#24273A";
          foreground = "#CAD3F5";
          timeout = 5;
        };
        urgency_normal = {
          background = "#24273A";
          foreground = "#CAD3F5";
          timeout = 10;
        };
        urgency_critical = {
          background = "#24273A";
          foreground = "#CAD3F5";
          frame_color = "#F5A97F";
          timeout = 0;
        };
      };
    };
  };
}
