{
  config,
  lib,
  pkgs,
  ...
}: {
  options.features = {
    # Core features (disabled by default)
    nix-ld.enable = lib.mkEnableOption "nix-ld support for running unpatched dynamic binaries";
    nix-index.enable = lib.mkEnableOption "nix-index for searching available packages";

    # Desktop features
    desktop = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable desktop environment";
      };
      hyprland.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable Hyprland desktop environment";
      };
      gnome.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable GNOME desktop environment";
      };
    };

    # Development features
    development = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable development environment";
      };
      python.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable Python development support";
      };
      rust.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable Rust development support";
      };
      go.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable Go development support";
      };
    };

    # Gaming features
    gaming = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable gaming support";
      };
      steam.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable Steam support";
      };
      wine.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable Wine support";
      };
      lutris.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable Lutris support";
      };
    };

    # Hardware features (disabled by default)
    nvidia = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable NVIDIA driver and CUDA support";
      };
    };
    amd = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable AMD driver and compute support";
      };
    };

    # Virtualization features (disabled by default)
    docker = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable Docker support";
      };
    };
    podman = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable Podman support";
      };
    };
    kvm = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable KVM/QEMU support";
      };
    };

    # WSL features (enabled by default)
    wsl = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable WSL support";
      };
      gui = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable WSL GUI support";
        };
      };
      cuda = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable WSL CUDA support";
        };
      };
    };
  };

  config = let
    cfg = config.features;
  in
    lib.mkMerge [
      # Feature version tracking
      {
        system.nixos.version = lib.mkIf (cfg != {}) (
          let
            enabledFeatures = lib.concatStringsSep "," (
              lib.mapAttrsToList (name: value:
                if (value.enable or value)
                then "${name}"
                else null)
              (lib.filterAttrs (name: _: name != "_module") cfg)
            );
          in "${config.system.nixos.version}+features.${enabledFeatures}"
        );
      }

      # Desktop features
      (lib.mkIf cfg.desktop.enable {
        # Common desktop settings
        services.xserver = {
          enable = true;
          displayManager.gdm.enable = true;
        };

        # Desktop environment specific settings
        services.xserver.desktopManager.gnome.enable = lib.mkIf cfg.desktop.gnome.enable true;
        programs = {
          hyprland.enable = lib.mkIf cfg.desktop.hyprland.enable true;
        };

        # Home-manager desktop settings
        home-manager.users.ryzengrind = lib.mkIf cfg.desktop.hyprland.enable {
          programs = {
            hyprlock.enable = true;
            hypridle.enable = true;
          };
        };

        # Common desktop packages
        environment.systemPackages = with pkgs; [
          # Basic desktop utilities
          xdg-utils
          xdg-user-dirs
          # Terminal emulator
          alacritty
          # File manager
          pcmanfm
          # Web browser
          firefox
        ];
      })

      # Development features
      (lib.mkIf cfg.development.enable {
        # Common development tools
        environment.systemPackages = with pkgs; [
          # Version control
          git
          git-lfs
          # Build tools
          gnumake
          gcc
          # Development tools
          direnv
          nixfmt
          alejandra
          statix
        ];
      })

      # Gaming features
      (lib.mkIf cfg.gaming.enable {
        # Gaming-specific packages
        environment.systemPackages = with pkgs;
          [
            # Gaming utilities
            mangohud
            gamemode
          ]
          ++ lib.optionals cfg.gaming.steam.enable [
            steam
            steam-run
          ]
          ++ lib.optionals cfg.gaming.wine.enable [
            wine
            winetricks
          ]
          ++ lib.optionals cfg.gaming.lutris.enable [
            lutris
          ];

        # Gaming-specific services
        services = {
          # Steam configuration
          steam.enable = cfg.gaming.steam.enable;
          # Game Mode daemon
          gamemode.enable = true;
        };
      })

      # Virtualization features
      (lib.mkIf cfg.docker.enable {
        virtualisation.docker = {
          enable = true;
          autoPrune = {
            enable = true;
            dates = "weekly";
          };
        };
      })

      (lib.mkIf cfg.podman.enable {
        virtualisation.podman = {
          enable = true;
          autoPrune = {
            enable = true;
            dates = "weekly";
          };
        };
      })

      (lib.mkIf cfg.kvm.enable {
        virtualisation.libvirtd = {
          enable = true;
          qemu = {
            package = pkgs.qemu_kvm;
            runAsRoot = true;
          };
        };
      })
    ];
}
