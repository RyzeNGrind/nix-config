{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkOption types;
  cfg = config.testing;
in {
  options.testing = {
    enable = lib.mkEnableOption "NixOS configuration testing";

    machine = mkOption {
      type = types.submodule {
        options = {
          memorySize = mkOption {
            type = types.int;
            default = 2048;
            description = "Memory allocation for test VM (MB)";
          };
          cores = mkOption {
            type = types.int;
            default = 2;
            description = "CPU cores for test VM";
          };
          qemuFlags = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "Additional QEMU flags";
          };
        };
      };
      default = {};
      description = "Test machine configuration";
    };

    suites = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          enable = lib.mkEnableOption "Test suite";
          description = mkOption {
            type = types.str;
            description = "Test suite description";
          };
          script = mkOption {
            type = types.str;
            description = "Python test script";
          };
          timeout = mkOption {
            type = types.int;
            default = 300;
            description = "Test timeout in seconds";
          };
        };
      });
      default = {};
      description = "Test suites to run";
    };

    coverage = {
      enable = lib.mkEnableOption "Test coverage reporting";
      outputPath = mkOption {
        type = types.str;
        default = "./coverage";
        description = "Path for coverage reports";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Basic test environment
    virtualisation = {
      inherit (cfg.machine) memorySize cores;
      qemu.options = cfg.machine.qemuFlags;
    };

    # Test dependencies
    environment.systemPackages = with pkgs; [
      python3
      python3Packages.pytest
      python3Packages.coverage
      nixos-test-runner
    ];

    # Test runner service
    systemd.services.test-runner = {
      description = "NixOS Test Runner";
      after = ["multi-user.target"];
      wantedBy = ["multi-user.target"];
      path = [pkgs.python3 pkgs.nixos-test-runner];
      environment = {
        COVERAGE_FILE = lib.mkIf cfg.coverage.enable "${cfg.coverage.outputPath}/.coverage";
      };
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = let
          testScript = pkgs.writeText "test-script.py" ''
            import os
            import sys
            import pytest
            from typing import Dict, List

            def run_suite(name: str, suite: Dict) -> None:
                print(f"\nRunning test suite: {name}")
                print(f"Description: {suite['description']}")

                with open(f"test_{name}.py", "w") as f:
                    f.write(suite['script'])

                args: List[str] = [
                    f"test_{name}.py",
                    f"--timeout={suite['timeout']}",
                ]
                if ${toString cfg.coverage.enable}:
                    args.extend(["--cov", "--cov-report=html"])

                result = pytest.main(args)
                if result != 0:
                    sys.exit(result)

            suites = ${builtins.toJSON cfg.suites}
            for name, suite in suites.items():
                if suite['enable']:
                    run_suite(name, suite)
          '';
        in "${pkgs.python3}/bin/python3 ${testScript}";
      };
    };

    # Coverage reporting
    systemd.services.coverage-report = lib.mkIf cfg.coverage.enable {
      description = "Generate test coverage report";
      after = ["test-runner.service"];
      wantedBy = ["multi-user.target"];
      path = [pkgs.python3];
      script = ''
        mkdir -p ${cfg.coverage.outputPath}
        cd ${cfg.coverage.outputPath}
        ${pkgs.python3}/bin/python3 -m coverage combine
        ${pkgs.python3}/bin/python3 -m coverage html
        ${pkgs.python3}/bin/python3 -m coverage report
      '';
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
    };
  };
}
