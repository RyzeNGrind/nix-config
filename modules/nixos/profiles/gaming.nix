{
  config,
  lib,
  pkgs,
  ...
}: {
  options.profiles.gaming = {
    enable = lib.mkEnableOption "Gaming environment profile";
    streaming.enable = lib.mkEnableOption "Game streaming support";
  };

  config = lib.mkIf config.profiles.gaming.enable {
    # Xen hypervisor configuration
    virtualisation = {
      xen = {
        enable = true;
        package = pkgs.xen;
        bootParams = {
          "dom0_mem" = "8192M";
          "dom0_vcpus_pin" = true;
        };
      };

      # QEMU/KVM for testing
      libvirtd.enable = true;
      spiceUSBRedirection.enable = true;
    };

    # Gaming-specific packages
    environment.systemPackages = with pkgs;
      [
        # Hypervisor management
        virt-manager
        looking-glass-client
        barrier # Mouse/keyboard sharing

        # Gaming utilities
        mangohud
        gamemode
        lutris
        winetricks

        # Streaming (if enabled)
      ]
      ++ lib.optionals config.profiles.gaming.streaming.enable [
        sunshine # Streaming host
        moonlight-qt # Streaming client
      ];

    # Hardware acceleration
    hardware = {
      opengl = {
        enable = true;
        driSupport = true;
        driSupport32Bit = true;
      };
      pulseaudio.support32Bit = true;
    };

    # Gaming-specific services
    services = {
      # Looking Glass shared memory
      looking-glass = {
        enable = true;
        memSize = "128M"; # Adjust based on resolution
      };

      # Sunshine streaming service
      sunshine = lib.mkIf config.profiles.gaming.streaming.enable {
        enable = true;
        package = pkgs.sunshine;
      };
    };

    # Gaming-specific kernel parameters
    boot = {
      kernelParams = [
        "intel_iommu=on"
        "iommu=pt"
        "vfio-pci.ids=10de:1c03,10de:10f1" # Example GPU IDs
      ];
      kernelModules = ["vfio" "vfio_iommu_type1" "vfio_pci" "vfio_virqfd"];
    };

    # Security settings for gaming
    security = {
      rtkit.enable = true;
      wrappers = {
        looking-glass-client = {
          owner = "root";
          group = "root";
          capabilities = "cap_sys_nice+ep";
          source = "${pkgs.looking-glass-client}/bin/looking-glass-client";
        };
      };
    };
  };
}
