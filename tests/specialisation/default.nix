# Specialisation test module
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkOption types;
  cfg = config.testing.specialisation;
in {
  options.testing.specialisation = {
    enable = lib.mkEnableOption "Specialisation testing";

    variants = mkOption {
      type = types.listOf types.str;
      default = ["wsl-cuda" "wsl-nocuda" "baremetal"];
      description = "List of specialisations to test";
    };

    tests = mkOption {
      type = types.attrsOf types.anything;
      default = {};
      description = "Test definitions for each specialisation";
    };
  };

  config = lib.mkIf cfg.enable {
    testing.specialisation.tests = {
      # WSL with CUDA tests
      wsl-cuda = {
        name = "wsl-cuda-test";
        nodes.machine = {
          config,
          pkgs,
          ...
        }: {
          specialisation.wsl-cuda.configuration = {
            wsl.enable = true;
            wsl.cuda.enable = true;
          };
        };
        testScript = ''
          machine.wait_for_unit("multi-user.target")

          with subtest("WSL CUDA configuration"):
              # Test WSL environment
              machine.succeed("test -f /etc/wsl.conf")
              machine.succeed("test -d /mnt/c")

              # Test CUDA environment
              machine.succeed("test -n \"$NVIDIA_DRIVER_CAPABILITIES\"")
              machine.succeed("test -n \"$NVIDIA_VISIBLE_DEVICES\"")
              machine.succeed("nvidia-smi")

              # Test GUI support
              machine.succeed("test -n \"$DISPLAY\"")
              machine.succeed("test -n \"$WAYLAND_DISPLAY\"")
        '';
      };

      # WSL without CUDA tests
      wsl-nocuda = {
        name = "wsl-nocuda-test";
        nodes.machine = {
          config,
          pkgs,
          ...
        }: {
          specialisation.wsl-nocuda.configuration = {
            wsl.enable = true;
            wsl.cuda.enable = false;
          };
        };
        testScript = ''
          machine.wait_for_unit("multi-user.target")

          with subtest("WSL configuration without CUDA"):
              # Test WSL environment
              machine.succeed("test -f /etc/wsl.conf")
              machine.succeed("test -d /mnt/c")

              # Verify CUDA is not enabled
              machine.fail("nvidia-smi")
              machine.fail("test -n \"$NVIDIA_DRIVER_CAPABILITIES\"")

              # Test basic functionality
              machine.succeed("wslpath -w /home")
              machine.succeed("wslpath -u 'C:\\'")
        '';
      };

      # Baremetal tests
      baremetal = {
        name = "baremetal-test";
        nodes.machine = {
          config,
          pkgs,
          ...
        }: {
          specialisation.baremetal.configuration = {
            wsl.enable = false;
            hardware.nvidia.enable = true;
          };
        };
        testScript = ''
          machine.wait_for_unit("multi-user.target")

          with subtest("Baremetal configuration"):
              # Test display manager
              machine.wait_for_unit("display-manager.service")
              machine.succeed("test -e /run/opengl-driver")

              # Test NVIDIA drivers
              machine.succeed("nvidia-smi")
              machine.succeed("test -e /dev/nvidia0")

              # Test sound system
              machine.succeed("systemctl is-active pipewire")
              machine.succeed("pactl info")

              # Test power management
              machine.succeed("systemctl is-active thermald")
              machine.succeed("systemctl is-active power-profiles-daemon")
        '';
      };
    };

    # Common test configuration
    virtualisation = {
      memorySize = 4096; # Increased for CUDA tests
      cores = 4;
      qemu.options = [
        "-cpu max"
        "-machine accel=kvm:tcg"
      ];
    };

    # Required packages for tests
    environment.systemPackages = with pkgs; [
      # Testing tools
      python3Packages.pytest
      python3Packages.pytest-xdist

      # System tools
      pciutils
      usbutils

      # Monitoring tools
      htop
      nvtop

      # X11 tools
      xorg.xhost
      xorg.xauth
      glxinfo
    ];
  };
}
