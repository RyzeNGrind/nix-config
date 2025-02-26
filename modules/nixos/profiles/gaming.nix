{
  config,
  lib,
  pkgs,
  ...
}: {
  options.profiles.gaming = {
    enable = lib.mkEnableOption "Gaming environment profile";
    streaming.enable = lib.mkEnableOption "Game streaming support";
    gpu-passthrough = {
      enable = lib.mkEnableOption "GPU passthrough support";
      looking-glass = {
        enable = lib.mkEnableOption "Looking Glass shared memory support";
        memSize = lib.mkOption {
          type = lib.types.str;
          default = "128M";
          description = "Size of shared memory for Looking Glass";
        };
      };
    };
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
      libvirtd = {
        enable = true;
        qemu = {
          package = pkgs.qemu_kvm;
          runAsRoot = true;
          swtpm.enable = true;
          ovmf = {
            enable = true;
            packages = with pkgs; [OVMFFull.fd];
          };
        };
      };
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

    # Looking Glass shared memory setup
    systemd.tmpfiles.rules = lib.mkIf config.profiles.gaming.gpu-passthrough.looking-glass.enable [
      "f /dev/shm/looking-glass 0660 ${config.users.users.ryzengrind.name} qemu-libvirtd -"
      "w /dev/shm/looking-glass - - - - ${config.profiles.gaming.gpu-passthrough.looking-glass.memSize}"
    ];

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
        looking-glass-client = lib.mkIf config.profiles.gaming.gpu-passthrough.looking-glass.enable {
          owner = "root";
          group = "root";
          capabilities = "cap_sys_nice+ep";
          source = "${pkgs.looking-glass-client}/bin/looking-glass-client";
        };
      };
    };

    # Streaming service configuration
    systemd.services.sunshine = lib.mkIf config.profiles.gaming.streaming.enable {
      description = "Sunshine streaming service";
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        ExecStart = "${pkgs.sunshine}/bin/sunshine";
        Restart = "always";
        RestartSec = "5";
      };
    };
  };
}
