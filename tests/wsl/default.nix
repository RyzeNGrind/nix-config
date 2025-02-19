# WSL test framework
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  inherit (lib) mkOption types;
  cfg = config.testing.wsl;
in {
  imports = [
    inputs.nixos-wsl.nixosModules.wsl
  ];

  options.testing.wsl = {
    enable = lib.mkEnableOption "WSL testing";

    features = mkOption {
      type = types.listOf types.str;
      default = ["base" "gui" "cuda"];
      description = "List of WSL features to test";
    };

    tests = mkOption {
      type = types.attrsOf types.anything;
      default = {};
      description = "Test definitions for WSL features";
    };
  };

  config = lib.mkIf cfg.enable {
    nodes.machine = {
      imports = [
        ../../modules/services/wsl.nix
      ];

      wsl = {
        enable = true;
        nativeSystemd = true;
        defaultUser = "ryzengrind";
        startMenuLaunchers = true;
        docker.enable = true;
      };

      # Required packages for WSL tests
      environment.systemPackages = with pkgs; [
        # WSL tools
        wslu
        wsl-open
        wsl-vpnkit

        # Testing tools
        python3Packages.pytest
        python3Packages.pytest-xdist

        # System tools
        pciutils
        usbutils
        curl
        wget

        # Development tools
        git
        gcc
        python3

        # X11/Wayland tools
        xorg.xhost
        xorg.xauth
        glxinfo
        wayland-utils

        # CUDA tools
        cudaPackages.cuda_nvcc
        cudaPackages.cuda_cupti
        cudaPackages.cudnn
        nvtop
      ];
    };

    testScript = ''
      machine.wait_for_unit("multi-user.target")

      with subtest("WSL base configuration"):
          # Test WSL environment
          machine.succeed("test -f /etc/wsl.conf")
          machine.succeed("test -d /mnt/c")
          machine.succeed("wslpath -w /home")
          machine.succeed("wslpath -u 'C:\\'")

          # Test systemd integration
          machine.succeed("systemctl is-active")
          machine.succeed("loginctl")

          # Test user setup
          machine.succeed("id ryzengrind")
          machine.succeed("groups ryzengrind | grep -q wheel")

      with subtest("WSL GUI configuration"):
          # Test display variables
          machine.succeed("test -n \"$DISPLAY\"")
          machine.succeed("test -n \"$WAYLAND_DISPLAY\"")
          machine.succeed("test -n \"$XDG_RUNTIME_DIR\"")

          # Test X11 forwarding
          machine.succeed("xhost +local:")
          machine.succeed("glxinfo | grep 'OpenGL vendor'")

          # Test GUI applications
          for cmd in ["firefox", "alacritty"]:
              machine.succeed(f"type -P {cmd}")

      with subtest("WSL CUDA configuration"):
          # Test CUDA environment
          machine.succeed("test -n \"$CUDA_PATH\"")
          machine.succeed("test -n \"$CUDA_HOME\"")
          machine.succeed("test -n \"$NVIDIA_DRIVER_CAPABILITIES\"")

          # Test CUDA tools
          machine.succeed("nvidia-smi")
          machine.succeed("nvcc --version")
          machine.succeed("python3 -c 'import torch; print(torch.cuda.is_available())'")

          # Test container support
          machine.succeed("docker run --rm --gpus all nvidia/cuda:12.0-base nvidia-smi")
    '';

    # Common test configuration
    virtualisation = {
      memorySize = 4096;
      cores = 4;
      graphics = true;
      qemu.options = [
        "-cpu max"
        "-machine accel=kvm:tcg"
      ];
    };
  };
}
