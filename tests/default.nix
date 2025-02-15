# Main test entry point
{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./core
    ./specialisation
    ./arch
  ];

  options.testing = {
    enable = lib.mkEnableOption "System testing";

    verbosity = lib.mkOption {
      type = lib.types.enum ["quiet" "normal" "verbose" "debug"];
      default = "normal";
      description = "Test output verbosity level";
    };

    parallelism = lib.mkOption {
      type = lib.types.int;
      default = 4;
      description = "Number of tests to run in parallel";
    };

    vm = {
      memory = lib.mkOption {
        type = lib.types.int;
        default = 2048;
        description = "Memory allocation for test VMs (MB)";
      };
      cores = lib.mkOption {
        type = lib.types.int;
        default = 2;
        description = "CPU cores for test VMs";
      };
    };
  };

  config = lib.mkIf config.testing.enable {
    # Common test dependencies
    environment.systemPackages = with pkgs; [
      python3
      qemu
      nixos-generators
    ];

    # Test VM configuration
    virtualisation = {
      memorySize = config.testing.vm.memory;
      inherit (config.testing.vm) cores;
      qemu.options = [
        "-cpu max"
        "-machine accel=kvm:tcg"
      ];
    };
  };
}
