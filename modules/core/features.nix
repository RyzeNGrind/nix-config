{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.features;
in {
  options.features = {
    # Core features (disabled by default)
    nix-ld.enable = lib.mkEnableOption "nix-ld support for running unpatched dynamic binaries";
    nix-index.enable = lib.mkEnableOption "nix-index for searching available packages";

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

    # Development features (disabled by default)
    dev = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable development environment";
      };
      python = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable Python development support";
        };
      };
      rust = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable Rust development support";
        };
      };
      go = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable Go development support";
        };
      };
    };

    # Gaming features (disabled by default)
    gaming = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable gaming support";
      };
      steam = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable Steam support";
        };
      };
      wine = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable Wine support";
        };
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

  config = {
    # Feature version tracking
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

    # Conditional module loading based on features
    imports = lib.mkMerge [
      # Hardware modules (disabled by default)
      (lib.mkIf cfg.nvidia.enable [../../modules/hardware/nvidia.nix])
      (lib.mkIf cfg.amd.enable [../../modules/hardware/amd.nix])

      # Virtualization modules (disabled by default)
      (lib.mkIf (cfg.docker.enable || cfg.podman.enable) [../../modules/services/containers.nix])
      (lib.mkIf cfg.kvm.enable [../../modules/services/virtualization.nix])

      # Development modules (disabled by default)
      (lib.mkIf cfg.dev.enable [../../modules/nixos/dev])

      # Gaming modules (disabled by default)
      (lib.mkIf cfg.gaming.enable [../../modules/nixos/gaming])

      # WSL modules (enabled by default)
      (lib.mkIf cfg.wsl.enable [../../modules/services/wsl.nix])
    ];

    # Feature-specific configurations
    environment.systemPackages = with pkgs;
      lib.mkMerge [
        # Nix tools (disabled by default)
        (lib.mkIf cfg.nix-index.enable [nix-index])

        # Development tools (disabled by default)
        (lib.mkIf cfg.dev.python.enable [python3Full python3Packages.pip])
        (lib.mkIf cfg.dev.rust.enable [rustup])
        (lib.mkIf cfg.dev.go.enable [go])

        # Gaming tools (disabled by default)
        (lib.mkIf cfg.gaming.steam.enable [steam-run])
        (lib.mkIf cfg.gaming.wine.enable [wine winetricks])

        # WSL tools (enabled by default)
        (lib.mkIf cfg.wsl.enable [
          wslu
          wsl-open
          wsl-vpnkit
        ])
      ];
  };
}
