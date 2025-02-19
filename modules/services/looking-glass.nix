{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.looking-glass;
in {
  options.services.looking-glass = {
    enable = mkEnableOption "Looking Glass shared memory file and service";

    package = mkOption {
      type = types.package;
      default = pkgs.looking-glass-client;
      defaultText = literalExpression "pkgs.looking-glass-client";
      description = "The Looking Glass package to use.";
    };

    memSize = mkOption {
      type = types.str;
      default = "128M";
      description = "Size of the shared memory file";
    };

    user = mkOption {
      type = types.str;
      default = "ryzengrind";
      description = "User under which Looking Glass runs";
    };

    group = mkOption {
      type = types.str;
      default = "kvm";
      description = "Group under which Looking Glass runs";
    };

    autoStart = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to start Looking Glass automatically on boot";
    };

    extraArgs = mkOption {
      type = types.listOf types.str;
      default = [];
      example = ["-f" "input:grabKeyboard=yes" "input:grabKeyboardOnFocus=yes"];
      description = "Additional arguments to pass to Looking Glass";
    };

    vfioIds = mkOption {
      type = types.listOf types.str;
      default = [];
      example = ["10de:1c03" "10de:10f1"];
      description = "PCI IDs for VFIO passthrough";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      # Create the shared memory file on boot
      systemd.tmpfiles.rules = [
        "f /dev/shm/looking-glass ${cfg.memSize} ${cfg.user} ${cfg.group} 0660 -"
      ];

      # Add the user to the kvm group
      users.users.${cfg.user}.extraGroups = ["kvm"];

      # Install Looking Glass package
      environment.systemPackages = [cfg.package];

      # Looking Glass service
      systemd.services.looking-glass = mkIf cfg.autoStart {
        description = "Looking Glass Client";
        wantedBy = ["graphical.target"];
        after = ["graphical.target"];

        serviceConfig = {
          Type = "simple";
          User = cfg.user;
          Group = cfg.group;
          ExecStart = "${cfg.package}/bin/looking-glass-client ${toString cfg.extraArgs}";
          Restart = "on-failure";
          RestartSec = "5s";
          AmbientCapabilities = ["CAP_SYS_NICE"];
        };

        environment = {
          DISPLAY = ":0";
          XDG_RUNTIME_DIR = "/run/user/1000";
        };
      };

      # Security settings for Looking Glass
      security.wrappers.looking-glass-client = {
        owner = "root";
        group = "root";
        capabilities = "cap_sys_nice+ep";
        source = "${cfg.package}/bin/looking-glass-client";
      };

      # Required for SPICE USB redirection
      services.spice-vdagentd.enable = true;
    }

    # IOMMU and VFIO configuration
    (mkIf (cfg.vfioIds != []) {
      boot = {
        # Combine all boot-related settings
        kernelModules = [
          "vfio"
          "vfio_iommu_type1"
          "vfio_pci"
          "vfio_virqfd"
        ];
        kernelParams = [
          # Enable IOMMU
          (
            if config.hardware.cpu.amd.updateMicrocode
            then "amd_iommu=on"
            else "intel_iommu=on"
          )
          "iommu=pt"
          # VFIO PCI IDs
          "vfio-pci.ids=${concatStringsSep "," cfg.vfioIds}"
        ];
        blacklistedKernelModules = ["nvidia" "nouveau"];
      };
    })

    # Virtualization configuration
    {
      # Enable required virtualization services
      virtualisation.libvirtd = {
        enable = true;
        qemu = {
          package = pkgs.qemu_kvm;
          ovmf = {
            enable = true;
            packages = [pkgs.OVMFFull];
          };
        };
      };

      # Add user to libvirt group
      users.users.${cfg.user}.extraGroups = ["libvirtd"];
    }
  ]);

  meta = {
    maintainers = with lib.maintainers; [ryzengrind];
    doc = ./looking-glass.md;
  };
}
