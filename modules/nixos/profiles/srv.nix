{ config, lib, pkgs, ... }:

{
  options.profiles.srv = {
    enable = lib.mkEnableOption "Server environment profile";
    
    role = lib.mkOption {
      type = lib.types.enum [ "controller" "worker" "edge" ];
      description = "Server role in the cluster";
    };

    monitoring.enable = lib.mkEnableOption "Monitoring stack";
    backup.enable = lib.mkEnableOption "Backup services";
    
    services = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "List of services to enable";
    };
  };

  config = lib.mkIf config.profiles.srv.enable {
    # Base server configuration
    services = {
      # SSH hardening
      openssh = {
        enable = true;
        settings = {
          PasswordAuthentication = false;
          PermitRootLogin = "no";
          X11Forwarding = false;
        };
        extraConfig = ''
          AllowTcpForwarding yes
          ClientAliveInterval 180
        '';
      };

      # Firewall configuration
      fail2ban.enable = true;

      # Monitoring stack
      prometheus = lib.mkIf config.profiles.srv.monitoring.enable {
        enable = true;
        exporters = {
          node = {
            enable = true;
            enabledCollectors = [ "systemd" ];
          };
        };
      };

      grafana = lib.mkIf config.profiles.srv.monitoring.enable {
        enable = true;
        settings.server = {
          domain = "metrics.local";
          http_port = 3000;
        };
      };

      # Automatic backup service
      borgbackup.jobs = lib.mkIf config.profiles.srv.backup.enable {
        system = {
          paths = [ "/etc" "/var/lib" ];
          exclude = [ "/var/lib/docker" ];
          repo = "/mnt/backup/system";
          encryption = {
            mode = "repokey";
            passCommand = "cat /etc/borgbackup/passphrase";
          };
          compression = "auto,lzma";
          startAt = "daily";
        };
      };
    };

    # Cluster management tools
    environment.systemPackages = with pkgs; [
      # Basic server tools
      htop
      iotop
      iftop
      ncdu
      tmux
      
      # Container tools
      docker-compose
      kubectl
      k9s
      
      # Monitoring tools
      prometheus
      grafana
      
      # Backup tools
      borgbackup
      restic
    ];

    # Container runtime
    virtualisation = {
      docker = {
        enable = true;
        autoPrune = {
          enable = true;
          dates = "weekly";
        };
      };

      containerd = {
        enable = true;
        settings = {
          plugins."io.containerd.grpc.v1.cri" = {
            containerd.runtimes.runc.options = {
              SystemdCgroup = true;
            };
          };
        };
      };
    };

    # Role-specific configurations
    services.kubernetes = lib.mkIf (config.profiles.srv.role == "controller") {
      roles = ["master"];
      masterAddress = "controller.local";
    };

    # System tweaks for server workloads
    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.bridge.bridge-nf-call-iptables" = 1;
      "vm.swappiness" = 10;
    };

    # Security hardening
    security = {
      audit.enable = true;
      auditd.enable = true;
      apparmor.enable = true;
      sudo.wheelNeedsPassword = true;
    };

    # Networking
    networking = {
      firewall.enable = true;
      firewall.allowedTCPPorts = [ 22 ];  # SSH only by default
      useDHCP = false;  # Prefer static configuration for servers
    };
  };
} 