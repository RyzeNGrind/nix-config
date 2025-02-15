{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkOption types;
  cfg = config.core.spec;
in {
  options.core.spec = {
    enable = lib.mkEnableOption "Core specialisation module";

    wsl = {
      enable = lib.mkEnableOption "WSL support";
      cuda = lib.mkEnableOption "CUDA support in WSL";
      gui = lib.mkEnableOption "GUI application support in WSL";
    };

    development = {
      enable = lib.mkEnableOption "Development environment";
      containers = lib.mkEnableOption "Container development tools";
      languages = mkOption {
        type = types.listOf (types.enum ["python" "rust" "go" "node"]);
        default = [];
        description = "Programming languages to enable";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # WSL configuration
    wsl = lib.mkIf cfg.wsl.enable {
      enable = true;
      startMenuLaunchers = cfg.wsl.gui;
      wslConf = {
        automount = {
          enabled = true;
          root = "/mnt";
        };
        network = {
          generateHosts = true;
          generateResolvConf = true;
        };
      };
    };

    # CUDA/NVIDIA configuration
    hardware.nvidia = lib.mkIf cfg.wsl.cuda {
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      modesetting.enable = true;
    };

    # Development environment
    environment.systemPackages = lib.mkMerge [
      # Language-specific packages
      (lib.mkIf (builtins.elem "python" cfg.development.languages) (with pkgs; [
        python3
        python3Packages.pip
        python3Packages.virtualenv
      ]))
      (lib.mkIf (builtins.elem "rust" cfg.development.languages) (with pkgs; [
        rustup
        cargo
      ]))
      (lib.mkIf (builtins.elem "go" cfg.development.languages) (with pkgs; [
        go
      ]))
      (lib.mkIf (builtins.elem "node" cfg.development.languages) (with pkgs; [
        nodejs
        yarn
      ]))
      # Container tools
      (lib.mkIf cfg.development.containers (with pkgs; [
        docker-compose
        kubectl
        helm
      ]))
    ];

    # Container support
    virtualisation = lib.mkIf cfg.development.containers {
      docker = {
        enable = true;
        autoPrune.enable = true;
      };
      podman = {
        enable = true;
        dockerCompat = true;
      };
    };

    # System tags
    core.system.tags = lib.mkMerge [
      (lib.mkIf cfg.wsl.enable ["wsl"])
      (lib.mkIf cfg.wsl.cuda ["cuda"])
      (lib.mkIf cfg.development.enable ["dev"])
    ];
  };
}
