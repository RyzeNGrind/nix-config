{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.cache.seaweed;
in {
  options.cache.seaweed = {
    enable = lib.mkEnableOption "SeaweedFS cache backend";

    master = {
      port = lib.mkOption {
        type = lib.types.port;
        default = 9333;
        description = "SeaweedFS master port";
      };

      peers = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "List of other master nodes";
      };
    };

    volume = {
      port = lib.mkOption {
        type = lib.types.port;
        default = 8080;
        description = "SeaweedFS volume port";
      };

      dataDir = lib.mkOption {
        type = lib.types.path;
        default = "/var/lib/seaweedfs";
        description = "Data directory for volumes";
      };

      replicas = lib.mkOption {
        type = lib.types.ints.between 1 3;
        default = 2;
        description = "Number of replicas for each file";
      };
    };

    metrics = {
      enable = lib.mkEnableOption "Prometheus metrics";
      port = lib.mkOption {
        type = lib.types.port;
        default = 9324;
        description = "Metrics port";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.seaweedfs-master = {
      description = "SeaweedFS Master";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];

      serviceConfig = {
        ExecStart = ''
          ${pkgs.seaweedfs}/bin/weed master \
            -port=${toString cfg.master.port} \
            ${lib.optionalString (cfg.master.peers != [])
            "-peers=${lib.concatStringsSep "," cfg.master.peers}"} \
            ${lib.optionalString cfg.metrics.enable
            "-metrics.port=${toString cfg.metrics.port}"}
        '';
        Restart = "always";
        User = "seaweedfs";
        Group = "seaweedfs";
        StateDirectory = "seaweedfs";
      };
    };

    systemd.services.seaweedfs-volume = {
      description = "SeaweedFS Volume";
      wantedBy = ["multi-user.target"];
      after = ["seaweedfs-master.service"];

      serviceConfig = {
        ExecStart = ''
          ${pkgs.seaweedfs}/bin/weed volume \
            -port=${toString cfg.volume.port} \
            -dir=${cfg.volume.dataDir} \
            -mserver=localhost:${toString cfg.master.port} \
            -dataCenter=dc1 \
            -rack=rack1 \
            ${lib.optionalString cfg.metrics.enable
            "-metrics.port=${toString (cfg.metrics.port + 1)}"}
        '';
        Restart = "always";
        User = "seaweedfs";
        Group = "seaweedfs";
        StateDirectory = "seaweedfs";
      };
    };

    # Create service user/group
    users.users.seaweedfs = {
      isSystemUser = true;
      group = "seaweedfs";
      home = cfg.volume.dataDir;
      createHome = true;
      description = "SeaweedFS service user";
    };

    users.groups.seaweedfs = {};

    # Configure nix to use SeaweedFS cache
    nix.settings = {
      extra-substituters = [
        "http://localhost:${toString cfg.volume.port}"
      ];
    };

    # Prometheus integration
    services.prometheus.scrapeConfigs = lib.mkIf cfg.metrics.enable [
      {
        job_name = "seaweedfs";
        static_configs = [
          {
            targets = [
              "localhost:${toString cfg.metrics.port}"
              "localhost:${toString (cfg.metrics.port + 1)}"
            ];
          }
        ];
      }
    ];

    environment.systemPackages = [pkgs.seaweedfs];
  };
}
