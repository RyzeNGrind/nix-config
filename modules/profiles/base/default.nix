{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.profiles.base;
in {
  options.profiles.base = {
    enable = mkEnableOption "Base system profile with core functionality";

    security = {
      enable = mkEnableOption "Enable security hardening";
      ssh = {
        enable = mkEnableOption "Enable SSH configuration";
        permitRootLogin = mkOption {
          type = types.bool;
          default = false;
          description = "Whether to allow root SSH login";
        };
      };
    };

    nix = {
      enable = mkEnableOption "Enable Nix-specific configurations";
      gc = {
        enable = mkEnableOption "Enable automatic garbage collection";
        dates = mkOption {
          type = types.str;
          default = "weekly";
          description = "How often to run garbage collection";
        };
      };
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      # Basic system configuration
      boot = {
        tmp.cleanOnBoot = true;
        loader.systemd-boot.configurationLimit = 10;
      };

      # Core system packages
      environment.systemPackages = with pkgs; [
        # System utilities
        coreutils
        curl
        wget
        git
        vim
        htop

        # Archive utilities
        gzip
        zip
        unzip

        # Process management
        psmisc
        lsof

        # Network utilities
        iproute2
        nettools

        # System monitoring
        sysstat
        lm_sensors
      ];

      # Basic system services
      services = {
        # Time synchronization
        timesyncd.enable = true;

        # System logging
        journald = {
          enable = true;
          extraConfig = ''
            SystemMaxUse=100M
            MaxRetentionSec=1week
          '';
        };
      };

      # Security configurations
      security = mkIf cfg.security.enable {
        # Basic hardening
        sudo.wheelNeedsPassword = true;

        # SSH configuration
        openssh = mkIf cfg.security.ssh.enable {
          enable = true;
          settings = {
            PermitRootLogin =
              if cfg.security.ssh.permitRootLogin
              then "yes"
              else "no";
            PasswordAuthentication = false;
          };
        };
      };

      # Nix configuration
      nix = mkIf cfg.nix.enable {
        settings = {
          auto-optimise-store = true;
          experimental-features = ["nix-command" "flakes"];
          trusted-users = ["root" "@wheel"];
        };

        gc = mkIf cfg.nix.gc.enable {
          automatic = true;
          inherit (cfg.nix.gc) dates;
          options = "--delete-older-than 30d";
        };
      };

      # System optimization
      zramSwap.enable = true;

      # Default locale settings
      i18n.defaultLocale = "en_US.UTF-8";
      console = {
        font = "Lat2-Terminus16";
        keyMap = "us";
      };

      # Time zone
      time.timeZone = "UTC";
    })
  ];
}
