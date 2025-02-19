# Comprehensive test framework for NixOS configurations
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  inherit (lib) mkOption types;
  cfg = config.testing;
in {
  imports = [
    ./core
    ./specialisation
    ./profiles
  ];

  options.testing = {
    enable = lib.mkEnableOption "Comprehensive testing framework";

    levels = {
      unit = mkOption {
        type = types.bool;
        default = true;
        description = "Enable unit tests";
      };

      integration = mkOption {
        type = types.bool;
        default = true;
        description = "Enable integration tests";
      };

      system = mkOption {
        type = types.bool;
        default = true;
        description = "Enable system tests";
      };
    };

    hooks = {
      pre-commit = mkOption {
        type = types.bool;
        default = true;
        description = "Enable pre-commit test hooks";
      };

      post-commit = mkOption {
        type = types.bool;
        default = true;
        description = "Enable post-commit test hooks";
      };
    };

    coverage = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable test coverage reporting";
      };

      threshold = mkOption {
        type = types.int;
        default = 80;
        description = "Minimum test coverage percentage required";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Test environment configuration
    virtualisation = {
      memorySize = 4096;
      cores = 4;
      graphics = true;
      useBootLoader = true;
      useEFIBoot = true;
      writableStore = true;
      qemu = {
        options = [
          "-cpu max"
          "-machine accel=kvm:tcg"
        ];
      };
    };

    # Test dependencies
    environment.systemPackages = with pkgs; [
      # Testing frameworks
      python3Packages.pytest
      python3Packages.pytest-xdist
      python3Packages.pytest-cov

      # Development tools
      git
      pre-commit

      # System tools
      pciutils
      usbutils
      procps
      iproute2

      # Monitoring
      htop
      nvtop

      # X11/Wayland
      xorg.xhost
      xorg.xauth
      glxinfo
      wayland-utils
    ];

    # Pre-commit hook configuration
    programs.pre-commit = {
      enable = true;
      hooks = {
        unit-tests = {
          enable = cfg.levels.unit;
          entry = "pytest tests/unit";
          files = "\\.(nix|py)$";
          language = "system";
          pass_filenames = false;
        };

        nix-format = {
          enable = true;
          entry = "alejandra --check";
          files = "\\.nix$";
          language = "system";
        };

        nix-static-analysis = {
          enable = true;
          entry = "statix check";
          files = "\\.nix$";
          language = "system";
        };
      };
    };

    # Post-commit hook configuration
    systemd.services.post-commit-tests = lib.mkIf cfg.hooks.post-commit {
      description = "Run post-commit tests";
      after = ["network.target"];
      wantedBy = ["multi-user.target"];
      path = with pkgs; [
        python3
        git
        nixFlakes
      ];
      environment = {
        NIX_PATH = "nixpkgs=${inputs.nixpkgs}";
      };
      script = ''
        # Run integration tests
        if [ "${toString cfg.levels.integration}" = "true" ]; then
          pytest tests/integration
        fi

        # Run system tests
        if [ "${toString cfg.levels.system}" = "true" ]; then
          pytest tests/system
        fi

        # Generate coverage report
        if [ "${toString cfg.coverage.enable}" = "true" ]; then
          pytest --cov=./ --cov-report=html tests/
          coverage_percent=$(coverage report | tail -1 | awk '{print $4}' | tr -d '%')
          if [ "$coverage_percent" -lt "${toString cfg.coverage.threshold}" ]; then
            echo "Test coverage ($coverage_percent%) below threshold (${toString cfg.coverage.threshold}%)"
            exit 1
          fi
        fi
      '';
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
    };

    # Test suite definitions
    testing = {
      # Core system tests
      core.enable = true;

      # Specialisation tests
      specialisation = {
        enable = true;
        variants = ["wsl-cuda" "wsl-nocuda" "baremetal"];
      };

      # Profile tests
      profiles = {
        enable = true;
        variants = [
          "base"
          "development"
          "gaming"
          "workstation"
          "server"
        ];
      };
    };
  };
}
