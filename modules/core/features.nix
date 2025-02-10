{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.features;
in {
  options.features = {
    # Core features
    nix-ld.enable = lib.mkEnableOption "nix-ld support for running unpatched dynamic binaries";
    nix-index.enable = lib.mkEnableOption "nix-index for searching available packages";

    # Hardware features
    nvidia.enable = lib.mkEnableOption "NVIDIA driver and CUDA support";
    amd.enable = lib.mkEnableOption "AMD driver and compute support";

    # Virtualization features
    docker.enable = lib.mkEnableOption "Docker support";
    podman.enable = lib.mkEnableOption "Podman support";
    kvm.enable = lib.mkEnableOption "KVM/QEMU support";

    # Development features
    dev = {
      enable = lib.mkEnableOption "Development environment";
      python.enable = lib.mkEnableOption "Python development support";
      rust.enable = lib.mkEnableOption "Rust development support";
      go.enable = lib.mkEnableOption "Go development support";
    };

    # Gaming features
    gaming = {
      enable = lib.mkEnableOption "Gaming support";
      steam.enable = lib.mkEnableOption "Steam support";
      wine.enable = lib.mkEnableOption "Wine support";
    };

    # WSL features
    wsl = {
      enable = lib.mkEnableOption "WSL support";
      gui.enable = lib.mkEnableOption "WSL GUI support";
      cuda.enable = lib.mkEnableOption "WSL CUDA support";
    };
  };

  config = {
    # Feature version tracking
    system.nixos.version = lib.mkIf (cfg != {}) (
      let
        enabledFeatures = lib.concatStringsSep "," (
          lib.mapAttrsToList (name: value:
            if value.enable or value
            then "${name}"
            else null)
          (lib.filterAttrs (name: _: name != "_module") cfg)
        );
      in "${config.system.nixos.version}+features.${enabledFeatures}"
    );

    # Conditional module loading based on features
    imports = lib.mkMerge [
      # Hardware modules
      (lib.mkIf cfg.nvidia.enable [../hardware/nvidia.nix])
      (lib.mkIf cfg.amd.enable [../hardware/amd.nix])

      # Virtualization modules
      (lib.mkIf (cfg.docker.enable || cfg.podman.enable) [../services/containers.nix])
      (lib.mkIf cfg.kvm.enable [../services/virtualization.nix])

      # Development modules
      (lib.mkIf cfg.dev.enable [../profiles/dev])

      # Gaming modules
      (lib.mkIf cfg.gaming.enable [../profiles/gaming])

      # WSL modules
      (lib.mkIf cfg.wsl.enable [../services/wsl.nix])
    ];

    # Feature-specific configurations
    environment.systemPackages = with pkgs;
      lib.mkMerge [
        # Nix tools
        (lib.mkIf cfg.nix-index.enable [nix-index])

        # Development tools
        (lib.mkIf cfg.dev.python.enable [python3Full python3Packages.pip])
        (lib.mkIf cfg.dev.rust.enable [rustup])
        (lib.mkIf cfg.dev.go.enable [go])

        # Gaming tools
        (lib.mkIf cfg.gaming.steam.enable [steam-run])
        (lib.mkIf cfg.gaming.wine.enable [wine winetricks])
      ];
  };
}
