{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./base
    ./gaming
    ./development
    ./server
    ./workstation
    ../services/wsl.nix
  ];

  options.profiles = {
    # Base profiles
    workstation = {
      enable = lib.mkEnableOption "Workstation profile with common desktop applications and settings";
    };

    gaming = {
      enable = lib.mkEnableOption "Gaming profile with Steam, Lutris, and performance optimizations";
      nvidia = lib.mkEnableOption "Enable NVIDIA-specific gaming optimizations";
      amd = lib.mkEnableOption "Enable AMD-specific gaming optimizations";
      virtualization = {
        enable = lib.mkEnableOption "Enable gaming-focused virtualization support";
        looking-glass = lib.mkEnableOption "Enable Looking Glass for VM GPU passthrough";
      };
    };

    development = {
      enable = lib.mkEnableOption "Development environment profile";
      ide = lib.mkOption {
        type = lib.types.enum ["vscode" "vscodium" "neovim" "cursor"];
        default = "vscodium";
        description = "Primary IDE to use";
      };
      vscodeRemote = {
        enable = lib.mkEnableOption "VSCode Remote support";
        method = lib.mkOption {
          type = lib.types.enum ["nix-ld" "patch"];
          default = "nix-ld";
          description = "Method to enable VSCode Remote support (nix-ld or patch)";
        };
      };
      ml = {
        enable = lib.mkEnableOption "Machine Learning support";
        cudaSupport = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable CUDA support for ML frameworks";
        };
        pytorch = {
          enable = lib.mkEnableOption "PyTorch support";
          package = lib.mkOption {
            type = lib.types.package;
            default = pkgs.python3Packages.pytorch.override {
              inherit (config.profiles.development.ml) cudaSupport;
              inherit (pkgs) cudaPackages;
            };
            description = "PyTorch package to use";
          };
        };
      };
    };

    server = {
      enable = lib.mkEnableOption "Server profile with hardened security and monitoring";
      type = lib.mkOption {
        type = lib.types.enum ["web" "database" "cache" "kubernetes"];
        default = "web";
        description = "Type of server to configure";
      };
    };

    wsl = {
      enable = lib.mkEnableOption "WSL-specific configuration and optimizations";
    };

    nas = {
      enable = lib.mkEnableOption "NAS profile with storage and sharing services";
      raid = lib.mkOption {
        type = lib.types.enum ["0" "1" "5" "6" "10"];
        description = "RAID level for storage configuration";
      };
    };

    cluster = {
      enable = lib.mkEnableOption "Cluster node profile";
      role = lib.mkOption {
        type = lib.types.enum ["master" "worker"];
        description = "Role of the node in the cluster";
      };
    };

    # Specialized profiles
    kvm = {
      enable = lib.mkEnableOption "KVM host profile with virtualization tools";
      gpu_passthrough = lib.mkEnableOption "Enable GPU passthrough support";
    };

    raspberry = {
      enable = lib.mkEnableOption "Raspberry Pi specific optimizations";
      model = lib.mkOption {
        type = lib.types.enum ["3b" "3bplus" "4b" "5"];
        description = "Raspberry Pi model";
      };
    };
  };
}
