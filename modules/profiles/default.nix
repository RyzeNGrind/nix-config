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
    ../services/looking-glass.nix
  ];

  options.profiles = {
    # Base profiles
    workstation = {
      enable = lib.mkEnableOption "Workstation profile with common desktop applications and settings";
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
