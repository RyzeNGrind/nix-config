{
  config,
  lib,
  pkgs,
  ...
}: {
  options.core.network = {
    enable = lib.mkEnableOption "Core network configuration";
    firewall = {
      enable = lib.mkEnableOption "Firewall configuration";
      allowPing = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to allow ICMP ping requests";
      };
      openPorts = lib.mkOption {
        type = lib.types.listOf lib.types.int;
        default = [];
        description = "List of ports to open in the firewall";
      };
    };
    optimization = {
      enable = lib.mkEnableOption "Network optimization features";
      tcp_bbr = lib.mkEnableOption "Enable TCP BBR congestion control";
    };
  };

  config = lib.mkIf config.core.network.enable {
    networking = {
      # Basic network configuration
      useDHCP = true;
      useNetworkd = true;
      firewall = lib.mkIf config.core.network.firewall.enable {
        enable = true;
        inherit (config.core.network.firewall) allowPing;
        inherit (config.core.network.firewall) openPorts;
      };

      # Network optimization
      networkmanager.enable = true;
    };

    # Network optimization settings
    boot.kernel.sysctl = lib.mkIf config.core.network.optimization.enable {
      # General network optimization
      "net.core.somaxconn" = 1024;
      "net.core.netdev_max_backlog" = 5000;
      "net.ipv4.tcp_max_syn_backlog" = 8096;
      "net.ipv4.tcp_max_tw_buckets" = 2000000;
      "net.ipv4.tcp_tw_reuse" = 1;
      "net.ipv4.tcp_fin_timeout" = 10;

      # TCP BBR congestion control
      "net.core.default_qdisc" = lib.mkIf config.core.network.optimization.tcp_bbr "fq";
      "net.ipv4.tcp_congestion_control" = lib.mkIf config.core.network.optimization.tcp_bbr "bbr";
    };

    # Network monitoring tools
    environment.systemPackages = with pkgs; [
      iftop
      nethogs
      tcpdump
      traceroute
      ethtool
      nmap
    ];

    # Systemd network configuration
    systemd.network = {
      enable = true;
      networks."10-wan" = {
        matchConfig.Name = "en*";
        networkConfig = {
          DHCP = "yes";
          MulticastDNS = true;
        };
      };
    };
  };
}
