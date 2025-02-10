{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.cache;
in {
  options.services.cache = {
    enable = lib.mkEnableOption "Binary cache service";

    type = lib.mkOption {
      type = lib.types.enum ["s3" "seaweed" "local" "attix"];
      default = "s3";
      description = "Type of cache backend to use";
    };

    maxSize = lib.mkOption {
      type = lib.types.str;
      default = "100G";
      description = "Maximum cache size";
    };

    pruneAfterDays = lib.mkOption {
      type = lib.types.int;
      default = 30;
      description = "Number of days after which to prune cache entries";
    };

    compression = {
      enable = lib.mkEnableOption "Cache compression";
      algorithm = lib.mkOption {
        type = lib.types.enum ["zstd" "lz4" "none"];
        default = "zstd";
        description = "Compression algorithm to use";
      };
      level = lib.mkOption {
        type = lib.types.int;
        default = 3;
        description = "Compression level";
      };
    };

    metrics = {
      enable = lib.mkEnableOption "Cache metrics";
      port = lib.mkOption {
        type = lib.types.port;
        default = 9100;
        description = "Port for Prometheus metrics";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Import the appropriate cache backend
    imports = [
      (./. + "/${cfg.type}.nix")
    ];

    # Common cache configuration
    nix.settings = {
      # Enable the binary cache
      substituters = lib.mkBefore [
        "http://localhost:${toString config.services.cache.metrics.port}"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];
      keep-outputs = true;
      keep-derivations = true;
    };

    # Cache monitoring
    services.prometheus = lib.mkIf cfg.metrics.enable {
      enable = true;
      exporters.node = {
        enable = true;
        enabledCollectors = ["nix" "systemd"];
        inherit (cfg.metrics) port;
      };
    };

    # Cache maintenance
    systemd.services.cache-maintenance = {
      description = "Binary cache maintenance";
      after = ["network.target"];
      startAt = "daily";
      script = ''
        # Prune old entries
        find /nix/store -type f -atime +${toString cfg.pruneAfterDays} -delete

        # Optimize storage
        nix-store --optimize

        # Collect garbage
        nix-collect-garbage --delete-older-than ${toString cfg.pruneAfterDays}d
      '';
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        IOSchedulingClass = "idle";
      };
    };

    # Cache compression
    environment.systemPackages = lib.mkIf cfg.compression.enable (with pkgs; [
      zstd
      lz4
    ]);

    # Metrics configuration
    metrics = {
      inherit (cfg.metrics) port;
    };
  };
}
