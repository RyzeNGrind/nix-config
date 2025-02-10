# Core system configuration module
{
  config,
  lib,
  pkgs,
  ...
}: {
  options.core.system = {
    enable = lib.mkEnableOption "Core system configuration";

    optimization = {
      enable = lib.mkEnableOption "System optimization features";

      zram = {
        enable = lib.mkEnableOption "ZRAM support";
        size = lib.mkOption {
          type = lib.types.str;
          default = "4G";
          description = "ZRAM size";
        };
      };

      io = {
        enable = lib.mkEnableOption "I/O optimization";
        scheduler = lib.mkOption {
          type = lib.types.enum ["none" "deadline" "cfq" "bfq"];
          default = "bfq";
          description = "I/O scheduler to use";
        };
      };
    };

    security = {
      enable = lib.mkEnableOption "Security hardening";

      kernel = {
        enable = lib.mkEnableOption "Kernel hardening";
        lockdown = lib.mkOption {
          type = lib.types.enum ["none" "integrity" "confidentiality"];
          default = "integrity";
          description = "Kernel lockdown mode";
        };
      };

      limits = {
        enable = lib.mkEnableOption "System resource limits";
        nofile = lib.mkOption {
          type = lib.types.int;
          default = 524288;
          description = "Maximum number of open files";
        };
      };
    };
  };

  config = lib.mkIf config.core.system.enable {
    # System optimization
    zramSwap = lib.mkIf config.core.system.optimization.zram.enable {
      enable = true;
      algorithm = "zstd";
      inherit (config.core.system.optimization.zram) size;
    };

    boot = {
      # Kernel parameters for system optimization
      kernelParams = lib.mkIf config.core.system.optimization.enable [
        # CPU optimizations
        "intel_pstate=active"
        "mitigations=off"

        # I/O optimizations
        "elevator=${config.core.system.optimization.io.scheduler}"
        "iommu=pt"

        # Memory management
        "transparent_hugepage=always"
      ];

      # Kernel hardening
      kernel.sysctl = lib.mkIf config.core.system.security.kernel.enable {
        # Kernel hardening
        "kernel.kptr_restrict" = 2;
        "kernel.dmesg_restrict" = 1;
        "kernel.printk" = "3 3 3 3";
        "kernel.unprivileged_bpf_disabled" = 1;
        "net.core.bpf_jit_harden" = 2;

        # Network hardening
        "net.ipv4.tcp_syncookies" = 1;
        "net.ipv4.tcp_rfc1337" = 1;
        "net.ipv4.conf.all.rp_filter" = 1;
        "net.ipv4.conf.default.rp_filter" = 1;

        # File system hardening
        "fs.protected_hardlinks" = 1;
        "fs.protected_symlinks" = 1;
      };
    };

    # System resource limits
    security.pam.loginLimits = lib.mkIf config.core.system.security.limits.enable [
      {
        domain = "*";
        type = "soft";
        item = "nofile";
        value = toString config.core.system.security.limits.nofile;
      }
      {
        domain = "*";
        type = "hard";
        item = "nofile";
        value = toString config.core.system.security.limits.nofile;
      }
    ];

    # Common system packages
    environment.systemPackages = with pkgs; [
      # System utilities
      htop
      iotop
      lsof
      psmisc

      # Monitoring tools
      sysstat
      procps

      # File system tools
      e2fsprogs
      btrfs-progs
    ];
  };
}
