# Example Gaming Workstation Configuration
{
  config,
  pkgs,
  ...
}: {
  imports = [
    # Import hardware configuration (you would generate this with nixos-generate-config)
    ./hardware-configuration.nix

    # Import our profiles module
    ../../modules/profiles
  ];

  # Profile configuration
  profiles = {
    workstation.enable = true;

    gaming = {
      enable = true;
      nvidia = true; # Enable if you have an NVIDIA GPU
      amd = false; # Disable AMD-specific optimizations
    };

    development = {
      enable = true;
      languages = ["cpp" "rust" "python"]; # Common game development languages
      containers = true; # Enable for game server containerization
    };
  };

  # Configure desktop features
  features.desktop = {
    enable = true;
    environment = "kde"; # KDE works well for gaming
    extras = {
      multimedia = true; # Enable multimedia apps
      browser = "firefox";
    };
  };

  # System-specific configuration
  networking.hostName = "gaming-station";

  # Add any additional system-specific configuration here
  environment.systemPackages = with pkgs; [
    discord # Gaming communication
    obs-studio # Streaming and recording
    mangohud # Gaming performance overlay
  ];

  # Enable services needed for gaming
  services = {
    # Enable Steam
    steam.enable = true;

    # Enable GameMode for better gaming performance
    gamemode.enable = true;

    # Enable OpenRGB for RGB control
    hardware.openrgb.enable = true;
  };

  # Performance tweaks
  boot = {
    kernelParams = [
      "nvidia-drm.modeset=1" # Better NVIDIA integration
      "intel_pstate=active" # Better CPU performance
    ];
    kernel.sysctl = {
      "vm.swappiness" = 10; # Reduce swap usage
    };
  };

  # Enable 32-bit support for Steam and other games
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };
}
