{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./x86_64
    ./aarch64
    ./cache.nix
  ];

  options.testing.arch = {
    enable = lib.mkEnableOption "Architecture-specific testing";

    qemu = {
      enable = lib.mkEnableOption "QEMU-based testing";
      memory = lib.mkOption {
        type = lib.types.int;
        default = 2048;
        description = "Memory allocation for QEMU VMs (MB)";
      };
      cores = lib.mkOption {
        type = lib.types.int;
        default = 2;
        description = "CPU cores for QEMU VMs";
      };
    };

    matrix = {
      enable = lib.mkEnableOption "Test matrix execution";
      architectures = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = ["x86_64-linux" "aarch64-linux"];
        description = "Architectures to test";
      };
      profiles = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = ["base" "dev" "gaming" "server"];
        description = "Profiles to test";
      };
    };
  };

  config = lib.mkIf config.testing.arch.enable {
    # QEMU configuration for cross-architecture testing
    virtualisation = lib.mkIf config.testing.arch.qemu.enable {
      inherit (config.testing.arch.qemu) cores memorySize;
      qemu = {
        package = pkgs.qemu;
        options = [
          "-cpu max"
          "-machine accel=kvm:tcg"
        ];
      };
    };

    # Test matrix configuration
    testing.matrix = lib.mkIf config.testing.arch.matrix.enable {
      nodes = {
        machine = {...}: {
          imports = [../../profiles/base/default.nix];
          virtualisation = {
            inherit (config.testing.arch.qemu) cores memorySize;
          };
        };
      };

      testScript = ''
        start_all()
        machine.wait_for_unit("multi-user.target")
        machine.succeed("nixos-rebuild dry-build")
      '';
    };

    # Common test dependencies
    environment.systemPackages = with pkgs; [
      nixos-generators
      qemu
      OVMF
    ];
  };
}
