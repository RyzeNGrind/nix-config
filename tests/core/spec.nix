{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../../modules/testing/core.nix
    ../../modules/core/spec.nix
  ];

  # Enable testing
  testing = {
    enable = true;
    coverage.enable = true;

    # Test suites
    suites.core-spec = {
      enable = true;
      description = "Core specialisation module tests";
      script = ''
        import os
        import pytest
        from typing import Any, Dict
        from nixostest import Machine

        @pytest.fixture
        def machine(request: Any) -> Machine:
            m = request.getfixturevalue("machine")
            m.wait_for_unit("multi-user.target")
            return m

        def test_wsl_specialisation(machine: Machine) -> None:
            """Test WSL specialisation configuration."""
            # Test WSL with CUDA
            machine.succeed("nixos-rebuild dry-activate --specialisation wsl-cuda")
            machine.succeed(
                "grep -q 'wsl.cuda.enable = true' /etc/nixos/specialisation/wsl-cuda/configuration.nix"
            )

            # Test WSL without CUDA
            machine.succeed("nixos-rebuild dry-activate --specialisation wsl-nocuda")
            machine.succeed(
                "grep -q 'wsl.cuda.enable = false' /etc/nixos/specialisation/wsl-nocuda/configuration.nix"
            )

        def test_development_environment(machine: Machine) -> None:
            """Test development environment configuration."""
            # Check development packages
            for pkg in ["python3", "rustup", "go", "nodejs"]:
                machine.succeed(f"type -P {pkg}")

            # Check container tools
            if ${toString config.core.spec.development.containers}:
                for tool in ["docker-compose", "kubectl", "helm"]:
                    machine.succeed(f"type -P {tool}")

        def test_specialisation_switching(machine: Machine) -> None:
            """Test specialisation switching."""
            # Test switching between specialisations
            for spec in ["wsl-cuda", "wsl-nocuda"]:
                machine.succeed(f"nixos-rebuild dry-activate --specialisation {spec}")
                machine.succeed(f"test -d /etc/nixos/specialisation/{spec}")

        def test_system_tags(machine: Machine) -> None:
            """Test system tags are properly set."""
            # Get system tags
            tags = machine.succeed(
                "readlink -f /run/current-system | grep -o '[^-]*$'"
            ).strip().split("-")

            # Check expected tags
            if ${toString config.core.spec.wsl.enable}:
                assert "wsl" in tags
            if ${toString config.core.spec.wsl.cuda}:
                assert "cuda" in tags
            if ${toString config.core.spec.development.enable}:
                assert "dev" in tags

        def test_environment_setup(machine: Machine) -> None:
            """Test environment configuration."""
            # Check environment variables
            if ${toString config.core.spec.wsl.cuda}:
                machine.succeed("test -n \"$CUDA_PATH\"")
                machine.succeed("test -n \"$NVIDIA_VISIBLE_DEVICES\"")
      '';
    };
  };

  # Test configuration
  core.spec = {
    enable = true;
    wsl = {
      enable = true;
      cuda = true;
      gui = true;
    };
    development = {
      enable = true;
      containers = true;
      languages = ["python" "rust" "go" "node"];
    };
  };
}
