{
  pkgs,
  lib,
  ...
}: {
  name = "development-profile";

  nodes = {
    machine = {
      config,
      pkgs,
      ...
    }: {
      imports = [./default.nix];

      profiles.development = {
        enable = true;
        ide = "vscodium";
        vscodeRemote = {
          enable = true;
          method = "nix-ld";
        };
        ml = {
          enable = true;
          cudaSupport = false;
          pytorch.enable = true;
        };
      };
    };

    machine-patch = {
      config,
      pkgs,
      ...
    }: {
      imports = [./default.nix];

      profiles.development = {
        enable = true;
        ide = "vscodium";
        vscodeRemote = {
          enable = true;
          method = "patch";
        };
      };
    };
  };

  testScript = ''
    start_all()

    with subtest("Basic development environment"):
        for node in ["machine", "machine-patch"]:
            # Test common development tools
            for cmd in ["git", "direnv", "cmake", "ninja"]:
                ${node}.succeed(f"type -P {cmd}")

            # Test IDE installation
            ${node}.succeed("type -P codium")

            # Test language servers and formatters
            for cmd in ["nil", "nixpkgs-fmt", "alejandra", "statix"]:
                ${node}.succeed(f"type -P {cmd}")

    with subtest("nix-ld configuration"):
        machine.succeed("systemctl is-enabled nix-ld")
        machine.succeed("test -e /run/current-system/sw/lib/nix-ld")

    with subtest("patch configuration"):
        machine-patch.succeed("test -x /etc/vscode-remote-workaround")
        machine-patch.succeed("systemctl --user is-enabled vscode-remote-patch")

    with subtest("ML environment"):
        # Test Python ML stack
        machine.succeed("python3 -c 'import numpy, pandas, torch, transformers'")
        machine.succeed("python3 -c 'import matplotlib.pyplot as plt'")
        machine.succeed("python3 -c 'import sklearn'")

    with subtest("Development environment configuration"):
        for node in ["machine", "machine-patch"]:
            # Test direnv integration
            ${node}.succeed("systemctl --user is-enabled direnv")

            # Test Nix development settings
            ${node}.succeed("nix-shell --version")
            ${node}.succeed("nix flake --version")

            # Test user permissions
            ${node}.succeed("groups | grep -q wheel")
  '';
}
