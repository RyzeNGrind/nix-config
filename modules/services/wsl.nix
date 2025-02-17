{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.wsl;
in {
  options.services.wsl = {
    enable = lib.mkEnableOption "WSL support";

    gui = {
      enable = lib.mkEnableOption "WSL GUI support";
      defaultDisplay = lib.mkOption {
        type = lib.types.str;
        default = ":0";
        description = "Default X display for WSL";
      };
    };

    cuda = {
      enable = lib.mkEnableOption "CUDA support in WSL";
      version = lib.mkOption {
        type = lib.types.str;
        default = "12.0";
        description = "CUDA version to use";
      };
    };

    automount = {
      enable = lib.mkEnableOption "Automount Windows drives";
      options = lib.mkOption {
        type = lib.types.str;
        default = "metadata,uid=1000,gid=100,umask=22,fmask=11";
        description = "Mount options for Windows drives";
      };
    };

    network = {
      generateHosts = lib.mkEnableOption "Generate /etc/hosts entries";
      nameservers = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = ["8.8.8.8" "8.8.4.4"];
        description = "List of nameservers to use";
      };
      search = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "List of search domains";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # WSL-specific system configuration
    wsl = {
      enable = true;
      defaultUser = "ryzengrind";
      startMenuLaunchers = true;
      nativeSystemd = true;

      # Automount configuration
      automountPath = "/mnt";
      automount = lib.mkIf cfg.automount.enable {
        enable = true;
        inherit (cfg.automount) options;
      };
    };

    # Network configuration
    networking = {
      nameservers = cfg.network.nameservers;
      search = cfg.network.search;
      hostFiles = lib.mkIf cfg.network.generateHosts [
        (pkgs.writeText "wsl-hosts" ''
          127.0.0.1 localhost
          127.0.0.1 ${config.networking.hostName}
          ::1 localhost
          ::1 ${config.networking.hostName}
        '')
      ];
    };

    # Environment configuration (GUI and CUDA support)
    environment = lib.mkMerge [
      (lib.mkIf cfg.gui.enable {
        sessionVariables = {
          DISPLAY = cfg.gui.defaultDisplay;
          WAYLAND_DISPLAY = "wayland-0";
          XDG_RUNTIME_DIR = "/run/user/1000";
          PULSE_SERVER = "unix:/run/user/1000/pulse/native";
        };

        systemPackages = with pkgs; [
          xorg.xhost
          xorg.xauth
          glxinfo
        ];
      })
      (lib.mkIf cfg.cuda.enable {
        variables = {
          NVIDIA_DRIVER_CAPABILITIES = "compute,utility";
          NVIDIA_VISIBLE_DEVICES = "all";
          NVIDIA_REQUIRE_CUDA = "cuda>=${cfg.cuda.version}";
        };
      })
    ];

    # WSL-specific systemd services
    systemd.services = lib.mkIf cfg.gui.enable {
      wsl-gui-setup = {
        description = "WSL GUI environment setup";
        wantedBy = ["multi-user.target"];
        after = ["network.target"];
        script = ''
          ${pkgs.xorg.xhost}/bin/xhost +local:
        '';
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
      };
    };

    # WSL-specific security settings
    security.sudo.wheelNeedsPassword = false;

    # WSL-specific file systems
    fileSystems = {
      "/" = {
        device = "none";
        fsType = "tmpfs";
        options = ["defaults"];
      };
    };

    # WSL configuration
    wslConf = {
      automount = {
        inherit (cfg.automount) options;
      };
      network = {
        generateResolvConf = false; # We're managing DNS settings through networking options
      };
    };
  };
}
