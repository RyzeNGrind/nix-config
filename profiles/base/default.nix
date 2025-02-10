{
  config,
  lib,
  pkgs,
  ...
}: {
  options.profiles.base = {
    enable = lib.mkEnableOption "Base system profile";
    security = {
      enable = lib.mkEnableOption "Enhanced security features";
      hardening = lib.mkEnableOption "System hardening features";
    };
  };

  config = lib.mkIf config.profiles.base.enable {
    # Core system settings
    nix = {
      settings = {
        auto-optimise-store = true;
        experimental-features = ["nix-command" "flakes"];
        trusted-users = ["root" "@wheel"];
        warn-dirty = false;
      };
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 30d";
      };
    };

    # Basic system security
    security = lib.mkIf config.profiles.base.security.enable {
      # PAM configuration
      pam = {
        loginLimits = [
          {
            domain = "@wheel";
            type = "soft";
            item = "nofile";
            value = "524288";
          }
        ];
      };

      # System hardening
      hardening = lib.mkIf config.profiles.base.security.hardening {
        enable = true;
        packages = with pkgs; [
          apparmor-profiles
          audit
          openscap
        ];
      };

      # Audit daemon
      auditd.enable = true;
      audit.enable = true;

      # Security features
      apparmor.enable = true;
      lockKernelModules = false;
      protectKernelImage = true;
      forcePageTableIsolation = true;
    };

    # Core system packages
    environment.systemPackages = with pkgs; [
      # System utilities
      coreutils
      curl
      git
      vim
      wget

      # System monitoring
      htop
      iotop
      lsof

      # Security tools
      gnupg
      openssl
    ];

    # Base system configuration
    boot = {
      tmp.cleanOnBoot = true;
      kernel.sysctl = {
        "kernel.panic" = 10;
        "kernel.panic_on_oops" = 1;
        "vm.swappiness" = 10;
      };
    };

    # System optimization
    zramSwap = {
      enable = true;
      algorithm = "zstd";
    };

    # Default system features
    features = {
      nix-ld.enable = true;
      nix-index.enable = true;
    };
  };
}
