{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.cache.s3;
in {
  options.cache.s3 = {
    enable = lib.mkEnableOption "Oracle S3 cache backend";

    bucket = lib.mkOption {
      type = lib.types.str;
      description = "S3 bucket name";
    };

    region = lib.mkOption {
      type = lib.types.str;
      default = "us-east-1";
      description = "S3 region";
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

    compression = {
      enable = lib.mkEnableOption "Enable compression";
      algorithm = lib.mkOption {
        type = lib.types.enum ["zstd" "xz" "none"];
        default = "zstd";
        description = "Compression algorithm";
      };
      level = lib.mkOption {
        type = lib.types.ints.between 1 22;
        default = 19;
        description = "Compression level";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    nix.settings = {
      extra-substituters = [
        "s3://${cfg.bucket}?endpoint=${cfg.endpoint}&region=${cfg.region}"
      ];

      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];
    };

    systemd.services.nix-daemon.environment = {
      AWS_ACCESS_KEY_ID = cfg.credentials.accessKeyId;
      AWS_SECRET_ACCESS_KEY = cfg.credentials.secretAccessKey;
      NIX_SECRET_KEY_FILE = "/var/cache-key";
    };

    environment.systemPackages = with pkgs; [
      awscli2
      s3cmd
    ];
  };
}
