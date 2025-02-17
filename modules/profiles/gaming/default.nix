{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.profiles.gaming;
in {
  options.profiles.gaming = {
    enable = mkEnableOption "Gaming environment profile";
    nvidia = mkEnableOption "Enable NVIDIA-specific gaming optimizations";
    amd = mkEnableOption "Enable AMD-specific gaming optimizations";
    virtualization = {
      enable = mkEnableOption "Enable gaming-focused virtualization support";
      looking-glass = mkEnableOption "Enable Looking Glass for VM GPU passthrough";
    };
  };

  config = mkIf cfg.enable {
    # Enable gaming features
    features = {
      gaming = {
        enable = true;
        steam.enable = true;
        wine.enable = true;
        lutris.enable = true;
      };
      nvidia.enable = cfg.nvidia;
      amd.enable = cfg.amd;
    };

    # Gaming-specific packages
    environment.systemPackages = with pkgs;
      [
        # Communication
        discord

        # Streaming and recording
        obs-studio

        # Performance monitoring
        psensor
        nvtop
      ]
      ++ lib.optionals cfg.virtualization.enable [
        virt-manager
        looking-glass-client
        barrier # Mouse/keyboard sharing
      ];

    # Virtualization support
    virtualisation = mkIf cfg.virtualization.enable {
      xen = {
        enable = true;
        package = pkgs.xen;
        bootParams = {
          "dom0_mem" = "8192M";
          "dom0_vcpus_pin" = true;
        };
      };

      libvirtd.enable = true;
      spiceUSBRedirection.enable = true;
    };

    # Looking Glass configuration
    services.looking-glass = mkIf cfg.virtualization.looking-glass {
      enable = true;
      memSize = "128M"; # Adjust based on resolution
    };

    # Hardware configuration
    hardware = {
      # OpenGL support
      opengl = {
        enable = true;
        driSupport = true;
        driSupport32Bit = true; # Needed for Steam
      };
    };

    # Performance tweaks
    boot = {
      kernelParams =
        [
          # CPU governor settings
          "intel_pstate=active"
          "processor.max_cstate=1"
          "idle=nomwait"

          # I/O settings
          "elevator=none"
          "transparent_hugepage=never"

          # IOMMU for virtualization
          "intel_iommu=on"
          "iommu=pt"
        ]
        ++ (
          if cfg.nvidia
          then [
            "nvidia-drm.modeset=1"
          ]
          else []
        );

      kernel.sysctl = {
        # Virtual memory settings
        "vm.swappiness" = 10;
        "vm.dirty_ratio" = 60;
        "vm.dirty_background_ratio" = 2;

        # Network settings
        "net.core.netdev_max_backlog" = 16384;
        "net.ipv4.tcp_fastopen" = 3;
        "net.ipv4.tcp_max_syn_backlog" = 8192;
      };

      kernelModules = mkIf cfg.virtualization.enable [
        "vfio"
        "vfio_iommu_type1"
        "vfio_pci"
        "vfio_virqfd"
      ];
    };

    # Enable services for RGB control
    services.hardware.openrgb = {
      enable = true;
      motherboard = "amd"; # or "intel" depending on your hardware
    };

    # Security settings for virtualization
    security = mkIf cfg.virtualization.enable {
      rtkit.enable = true;
      wrappers = {
        looking-glass-client = mkIf cfg.virtualization.looking-glass {
          owner = "root";
          group = "root";
          capabilities = "cap_sys_nice+ep";
          source = "${pkgs.looking-glass-client}/bin/looking-glass-client";
        };
      };
    };
  };
}
