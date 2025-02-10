{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.cache;
  s3Cfg = cfg.s3;
in {
  options.services.cache.s3 = {
    bucket = lib.mkOption {
      type = lib.types.str;
      description = "S3 bucket name";
    };

    region = lib.mkOption {
      type = lib.types.str;
      default = "us-east-1";
      description = "Oracle Cloud region";
    };

    endpoint = lib.mkOption {
      type = lib.types.str;
      description = "Oracle S3 endpoint URL";
    };

    credentials = {
      accessKeyId = lib.mkOption {
        type = lib.types.str;
        description = "AWS access key ID";
      };

      secretAccessKey = lib.mkOption {
        type = lib.types.str;
        description = "AWS secret access key";
      };
    };

    maxConnections = lib.mkOption {
      type = lib.types.int;
      default = 100;
      description = "Maximum number of concurrent S3 connections";
    };

    uploadChunkSize = lib.mkOption {
      type = lib.types.int;
      default = 5242880; # 5MB
      description = "Size of chunks for multipart uploads";
    };
  };

  config = lib.mkIf (cfg.enable && cfg.type == "s3") {
    # S3 cache service
    systemd.services.s3-cache = {
      description = "S3 Binary Cache Service";
      wantedBy = ["multi-user.target"];
      after = ["network-online.target"];
      path = [pkgs.nix];

      environment = {
        AWS_ACCESS_KEY_ID = s3Cfg.credentials.accessKeyId;
        AWS_SECRET_ACCESS_KEY = s3Cfg.credentials.secretAccessKey;
        AWS_DEFAULT_REGION = s3Cfg.region;
        AWS_ENDPOINT_URL = s3Cfg.endpoint;
        NIX_SECRET_KEY_FILE = "/var/lib/s3-cache/secret-key";
      };

      serviceConfig = {
        ExecStart = ''
          ${pkgs.nix}/bin/nix-serve \
            --port ${toString cfg.metrics.port} \
            --compression ${cfg.compression.algorithm} \
            --compression-level ${toString cfg.compression.level} \
            --store s3://${s3Cfg.bucket}?region=${s3Cfg.region}&endpoint=${s3Cfg.endpoint} \
            --max-connections ${toString s3Cfg.maxConnections} \
            --chunk-size ${toString s3Cfg.uploadChunkSize}
        '';
        Restart = "always";
        RestartSec = "10s";
        StateDirectory = "s3-cache";
        User = "s3-cache";
        Group = "s3-cache";

        # Security hardening
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectKernelTunables = true;
        ProtectControlGroups = true;
        RestrictAddressFamilies = ["AF_INET" "AF_INET6"];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        SystemCallArchitectures = "native";
      };
    };

    # Create service user
    users.users.s3-cache = {
      isSystemUser = true;
      group = "s3-cache";
      description = "S3 cache service user";
    };

    users.groups.s3-cache = {};

    # Add required packages
    environment.systemPackages = with pkgs; [
      awscli2
      nix-serve
    ];

    # Configure nix to use the S3 cache
    nix.settings = {
      substituters = [
        "s3://${s3Cfg.bucket}?region=${s3Cfg.region}&endpoint=${s3Cfg.endpoint}"
      ];
      extra-sandbox-paths = [
        "/var/lib/s3-cache"
      ];
    };

    # Monitoring integration
    services.prometheus.scrapeConfigs = lib.mkIf cfg.metrics.enable [
      {
        job_name = "s3-cache";
        static_configs = [
          {
            targets = [
              "localhost:${toString cfg.metrics.port}"
            ];
          }
        ];
      }
    ];
  };
}
