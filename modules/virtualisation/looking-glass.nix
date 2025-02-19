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
  };

  config = mkIf cfg.enable {
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
      wantedBy = ["graphical-target"];
      after = ["graphical.target"];

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        ExecStart = "${cfg.package}/bin/looking-glass-client ${toString cfg.extraArgs}";
        Restart = "on-failure";
        RestartSec = "5s";
      };

      environment = {
        DISPLAY = ":0";
        XDG_RUNTIME_DIR = "/run/user/1000";
      };
    };

    # Required kernel modules and parameters for IOMMU and VFIO
    boot = {
      kernelModules = [
        "vfio"
        "vfio_iommu_type1"
        "vfio_pci"
        "vfio_virqfd"
      ];

      kernelParams = [
        "intel_iommu=on" # For Intel CPUs
        "amd_iommu=on" # For AMD CPUs
        "iommu=pt"
        "vfio-pci.ids=10de:1c03,10de:10f1" # Example for NVIDIA GPU, adjust for your hardware
      ];

      blacklistedKernelModules = ["nvidia" "nouveau"];
    };

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

    # Security settings for Looking Glass
    security.wrappers.looking-glass-client = {
      owner = "root";
      group = "root";
      capabilities = "cap_sys_nice+ep";
      source = "${cfg.package}/bin/looking-glass-client";
    };

    # Required for SPICE USB redirection
    services.spice-vdagentd.enable = true;
  };
}
