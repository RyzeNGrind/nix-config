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
    # CPU microcode updates
    cpu.intel.updateMicrocode = true;

    # NVIDIA configuration
    nvidia = {
      modesetting.enable = true;
      powerManagement = {
        enable = true;
        finegrained = true;
      };
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      prime = {
        sync.enable = true;
        nvidiaBusId = "PCI:1:0:0";
        intelBusId = "PCI:0:2:0";
      };
    };

    # OpenGL configuration
    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
      extraPackages = with pkgs; [
        intel-media-driver
        vaapiIntel
        vaapiVdpau
        libvdpau-va-gl
      ];
    };

    # Audio configuration
    pulseaudio.enable = false;
  };

  # Boot configuration
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelParams = [
      "nvidia-drm.modeset=1"
      "intel_pstate=active"
    ];
    kernelModules = ["kvm-intel"];
    extraModulePackages = [config.boot.kernelPackages.nvidia_x11];
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

  # Sound and security configuration
  sound.enable = true;
  security.rtkit.enable = true;

  # Power management
  powerManagement = {
    enable = true;
    cpuFreqGovernor = "performance";
  };

  # Additional system packages
  environment.systemPackages = with pkgs; [
    # Desktop utilities
    gnome.gnome-tweaks
    gnome.dconf-editor
    gnome.adwaita-icon-theme
    xdg-utils
    xdg-desktop-portal-gtk

    # Hardware monitoring
    lm_sensors
    powertop
    s-tui

    # Graphics utilities
    glxinfo
    vulkan-tools
    nvidia-vaapi-driver
  ];

  # Testing configuration
  testing = {
    enable = true;
    testScript = ''
      # Test X11 configuration
      with subtest("X11 configuration"):
          machine.wait_for_unit("display-manager.service")
          machine.wait_for_x()
          machine.succeed("xrandr --listproviders")

      # Test NVIDIA configuration
      with subtest("NVIDIA configuration"):
          machine.succeed("nvidia-smi")
          machine.succeed("glxinfo | grep -i nvidia")
          machine.succeed("vulkaninfo | grep -i nvidia")

      # Test sound configuration
      with subtest("Sound configuration"):
          machine.wait_for_unit("pipewire.service")
          machine.succeed("pactl info")
          machine.succeed("pw-cli info")

      # Test power management
      with subtest("Power management"):
          machine.succeed("powerprofilesctl")
          machine.succeed("sensors")
          machine.succeed("cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor | grep performance")
    '';
  };
}
