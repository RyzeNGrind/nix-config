{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.profiles;
in {
  imports = [
    ./base
    ./gaming
    ./development
    ./server
    ./workstation
  ];

  options.profiles = {
    # Base profiles
    workstation = {
      enable = mkEnableOption "Workstation profile with common desktop applications and settings";
    };

    gaming = {
      enable = mkEnableOption "Gaming profile with Steam, Lutris, and performance optimizations";
      nvidia = mkEnableOption "Enable NVIDIA-specific gaming optimizations";
      amd = mkEnableOption "Enable AMD-specific gaming optimizations";
    };

    development = {
      enable = mkEnableOption "Development environment profile";
      languages = mkOption {
        type = types.listOf types.str;
        default = [];
        example = ["python" "rust" "go"];
        description = "Programming languages to include in the development environment";
      };
      containers = mkEnableOption "Enable container development tools";
      kubernetes = mkEnableOption "Enable Kubernetes development tools";
    };

    server = {
      enable = mkEnableOption "Server profile with hardened security and monitoring";
      type = mkOption {
        type = types.enum ["web" "database" "cache" "kubernetes"];
        default = "web";
        description = "Type of server to configure";
      };
    };

    wsl = {
      enable = mkEnableOption "WSL-specific configuration and optimizations";
    };

    nas = {
      enable = mkEnableOption "NAS profile with storage and sharing services";
      raid = mkOption {
        type = types.enum ["0" "1" "5" "6" "10"];
        description = "RAID level for storage configuration";
      };
    };

    cluster = {
      enable = mkEnableOption "Cluster node profile";
      role = mkOption {
        type = types.enum ["master" "worker"];
        description = "Role of the node in the cluster";
      };
    };

    # Specialized profiles
    kvm = {
      enable = mkEnableOption "KVM host profile with virtualization tools";
      gpu_passthrough = mkEnableOption "Enable GPU passthrough support";
    };

    raspberry = {
      enable = mkEnableOption "Raspberry Pi specific optimizations";
      model = mkOption {
        type = types.enum ["3b" "3bplus" "4b" "5"];
        description = "Raspberry Pi model";
      };
    };
  };

  config = mkMerge [
    (mkIf cfg.workstation.enable {
      imports = [./workstation/default.nix];
    })

    (mkIf cfg.gaming.enable {
      imports = [./gaming/default.nix];
    })

    (mkIf cfg.development.enable {
      imports = [./development/default.nix];
    })

    (mkIf cfg.server.enable {
      imports = [./server/default.nix];
    })

    (mkIf cfg.wsl.enable {
      imports = [../services/wsl.nix];
    })

    (mkIf cfg.nas.enable {
      # Import NAS-specific modules and features
      imports = [
        ../features/storage
        ../features/sharing
      ];
    })

    (mkIf cfg.cluster.enable {
      # Import cluster-specific modules and features
      imports = [
        ../features/cluster
        ../features/networking
      ];
    })

    (mkIf cfg.kvm.enable {
      # Import KVM-specific modules and features
      imports = [
        ../features/virtualization
        (mkIf cfg.kvm.gpu_passthrough ../features/gpu-passthrough)
      ];
    })

    (mkIf cfg.raspberry.enable {
      # Import Raspberry Pi-specific modules and features
      imports = [
        ../features/raspberry-pi
      ];
    })
  ];
}
