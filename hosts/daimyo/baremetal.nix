# Baremetal configuration
{
  config,
  lib,
  pkgs,
  ...
}: {
  # Import base configuration
  imports = [
    ../base/default.nix
  ];

  # Hardware configuration
  hardware = {
    cpu.intel.updateMicrocode = true;
    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
    };
    nvidia = {
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      modesetting.enable = true;
    };
  };

  # Boot configuration
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelModules = ["kvm-intel"];
    kernelParams = ["nvidia-drm.modeset=1"];
  };

  # System services
  services = {
    xserver = {
      enable = true;
      displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;
      videoDrivers = ["nvidia"];
      layout = "us";
      xkbVariant = "";
    };
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };
    thermald.enable = true;
    power-profiles-daemon.enable = true;
  };

  # Additional system packages
  environment.systemPackages = with pkgs; [
    # System utilities
    htop
    iotop
    powertop
    lm_sensors
    # Hardware monitoring
    nvtop
    intel-gpu-tools
    # Power management
    tlp
    powertop
  ];

  # Testing configuration
  testing.suites.baremetal = {
    enable = true;
    description = "Baremetal configuration tests";
    script = ''
      import pytest
      from nixostest import Machine

      def test_x11(machine: Machine) -> None:
          """Test X11 configuration."""
          machine.succeed("systemctl is-active display-manager")
          machine.succeed("test -e /run/opengl-driver")

      def test_nvidia(machine: Machine) -> None:
          """Test NVIDIA configuration."""
          machine.succeed("nvidia-smi")
          machine.succeed("test -e /dev/nvidia0")

      def test_sound(machine: Machine) -> None:
          """Test sound configuration."""
          machine.succeed("systemctl is-active pipewire")
          machine.succeed("pactl info")

      def test_power(machine: Machine) -> None:
          """Test power management."""
          machine.succeed("systemctl is-active thermald")
          machine.succeed("systemctl is-active power-profiles-daemon")
          machine.succeed("tlp-stat")
    '';
  };
}
