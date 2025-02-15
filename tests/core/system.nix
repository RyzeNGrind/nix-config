{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../../modules/testing/core.nix
    ../../modules/core/system.nix
  ];

  # Enable testing
  testing = {
    enable = true;
    coverage.enable = true;

    # Test suites
    suites.core-system = {
      enable = true;
      description = "Core system module tests";
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

        def test_flake_inputs(machine: Machine) -> None:
            """Test flake inputs are properly stored."""
            # Check /etc/nixpkgs exists
            machine.succeed("test -d /etc/nixpkgs")
            machine.succeed("test -d /etc/self")

        def test_generation_source(machine: Machine) -> None:
            """Test generation source is properly linked."""
            machine.succeed("test -L /run/current-system/src")

        def test_system_version(machine: Machine) -> None:
            """Test system version and label."""
            # Get system version
            version = machine.succeed("nixos-version").strip()

            # Should contain state version
            assert "24.05" in version

            # Should contain git commit
            assert "." in version

            # Should contain tags if any
            tags = machine.succeed(
                "readlink -f /run/current-system | grep -o '[^-]*$'"
            ).strip()
            assert len(tags) > 0

        def test_system_state(machine: Machine) -> None:
            """Test system state configuration."""
            # Check state version
            machine.succeed(
                "grep -q 'system.stateVersion = \"24.05\"' /etc/nixos/configuration.nix"
            )

        def test_system_builder(machine: Machine) -> None:
            """Test system builder commands."""
            # Check builder output
            machine.succeed("test -d /run/current-system/sw")
            machine.succeed("test -d /run/current-system/etc")
      '';
    };
  };

  # Test configuration
  core.system = {
    enable = true;
    stateVersion = "24.05";
    flakeInputs = {
      self = pkgs.hello; # Mock flake input for testing
      nixpkgs = pkgs.path;
    };
    tags = ["test" "core"];
  };
}
