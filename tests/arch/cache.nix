{
  config,
  lib,
  pkgs,
  ...
}: {
  options.testing.cache = {
    enable = lib.mkEnableOption "Cache testing";

    type = lib.mkOption {
      type = lib.types.enum ["s3" "seaweed" "local"];
      default = "seaweed";
      description = "Type of cache to test";
    };

    seaweed = {
      enable = lib.mkEnableOption "SeaweedFS cache testing";
      port = lib.mkOption {
        type = lib.types.port;
        default = 8333;
        description = "SeaweedFS port";
      };
    };

    s3 = {
      enable = lib.mkEnableOption "S3 cache testing";
      endpoint = lib.mkOption {
        type = lib.types.str;
        default = "http://localhost:4566";
        description = "S3 endpoint URL";
      };
      bucket = lib.mkOption {
        type = lib.types.str;
        default = "test-cache";
        description = "S3 bucket name";
      };
    };

    local = {
      enable = lib.mkEnableOption "Local cache testing";
      path = lib.mkOption {
        type = lib.types.path;
        default = "/tmp/nix-cache";
        description = "Local cache path";
      };
    };

    verification = {
      enable = lib.mkEnableOption "Cache verification testing";
      derivations = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [];
        description = "Test derivations to build and cache";
      };
    };
  };

  config = lib.mkIf config.testing.cache.enable {
    # Test matrix configuration
    testing.matrix = {
      nodes = {
        cache = {...}: {
          imports = [../../modules/cache];
          services.cache = {
            enable = true;
            inherit (config.testing.cache) type;
            maxSize = "10G";
            pruneAfterDays = 7;
            compression = {
              enable = true;
              algorithm = "zstd";
              level = 3;
            };
            metrics = {
              enable = true;
              port = 9100;
            };
          };
        };
      };

      testScript = ''
        start_all()
        cache.wait_for_unit("multi-user.target")

        # Test cache service
        cache.succeed("systemctl is-active cache")

        # Test cache metrics
        cache.wait_for_open_port(9100)
        cache.succeed("curl -f http://localhost:9100/metrics")
      '';
    };

    # Test nodes configuration
    nodes = {
      s3-cache = {...}: {
        imports = [../../modules/cache];
        services.cache = {
          enable = true;
          type = "s3";
          s3 = {
            enable = true;
            inherit (config.testing.cache.s3) bucket endpoint;
            region = "us-east-1";
            credentials = {
              accessKeyId = "test";
              secretAccessKey = "test";
            };
          };
        };
      };

      seaweed-master = {...}: {
        imports = [../../modules/cache];
        services.cache = {
          enable = true;
          type = "seaweed";
          seaweed = {
            enable = true;
            master.port = config.testing.cache.seaweed.port;
            metrics.enable = true;
          };
        };
      };
    };

    # Test script
    testScript = ''
      start_all()

      # Test S3 cache
      with subtest("S3 cache"):
          s3-cache.wait_for_unit("docker.service")
          s3-cache.succeed(
              "docker run -d --name localstack --network=cache-test"
              + " -e SERVICES=s3 -p 4566:4566 localstack/localstack"
          )
          s3-cache.wait_until_succeeds("curl -s http://localstack:4566")
          s3-cache.succeed(
              "aws --endpoint-url=http://localstack:4566 s3 mb"
              + " s3://${config.testing.cache.s3.bucket}"
          )

      # Test SeaweedFS cache
      with subtest("SeaweedFS cache"):
          seaweed-master.wait_for_unit("seaweedfs-master.service")
          seaweed-master.wait_for_open_port(${toString config.testing.cache.seaweed.port})

          for n in range(1, ${toString config.testing.cache.seaweed.nodes + 1}):
              machine = machines[f"seaweed-volume-{n}"]
              machine.wait_for_unit("seaweedfs-volume.service")
              machine.wait_for_open_port(8080 + n)

      # Test cache verification
      with subtest("Cache verification"):
          ${lib.concatMapStrings (drv: ''
          # Build and push to cache
          s3-cache.succeed("nix-store --add-fixed sha256 ${drv}")
          s3-cache.succeed("nix copy --to 's3://${config.testing.cache.s3.bucket}' ${drv}")

          # Verify in SeaweedFS
          seaweed-master.succeed("nix-store --verify ${drv}")
        '')
        config.testing.cache.verification.derivations}
    '';

    # Test dependencies
    virtualisation = {
      docker.enable = true;
      docker.extraOptions = "--network=cache-test";
    };

    environment.systemPackages = with pkgs; [
      awscli2
      curl
      jq
    ];
  };
}
