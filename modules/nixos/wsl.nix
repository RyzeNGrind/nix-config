# WSL-specific NixOS configuration
{ config, lib, pkgs, ... }:

{
  # Common WSL-specific system configurations
  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = false;

  # Enable OpenGL and NVIDIA support
  hardware = {
    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
    };
    nvidia = {
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      modesetting.enable = true;
      powerManagement = {
        enable = false;
        finegrained = false;
      };
      open = false;
      nvidiaSettings = true;
    };
  };

  # Disable services that don't make sense in WSL
  services.xserver = {
    enable = false;
    desktopManager.gnome.enable = false;
    displayManager.gdm.enable = false;
  };
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  # WSL-specific shell configuration
  programs.bash.loginShellInit = ''
    if [ "''${WSL_DISTRO_NAME}" = "NixOS" ]; then
      # WSL-specific environment setup
      export BROWSER="wslview"
      export NIXOS_WSL=1
    fi
  '';

  # WSL-specific environment configuration
  environment = {
    sessionVariables = {
      NIXOS_WSL = "1";
      BROWSER = "wslview";
      DISPLAY = ":0";
      # NVIDIA CUDA environment variables
      NVIDIA_VISIBLE_DEVICES = "all";
      NVIDIA_DRIVER_CAPABILITIES = "compute,utility,graphics";
      CUDA_CACHE_PATH = "$HOME/.cache/cuda";
    };
    
    pathsToLink = [ "/libexec" ];

    systemPackages = with pkgs; [
      # WSL utilities
      wslu
      wsl-open
      xclip
      xsel
      
      # NVIDIA development tools
      cudaPackages.cuda_cudart
      cudaPackages.cuda_cupti
      cudaPackages.cuda_nvcc
      cudaPackages.tensorrt
      cudaPackages.cudnn
      nvidia-docker
      nvtop.full
    ];
  };

  # WSL-specific security settings
  security.sudo.wheelNeedsPassword = false;  # Easier sudo access in WSL

  # WSL-specific networking settings
  networking = {
    useHostResolvConf = false;  # Don't use Windows DNS directly
    networkmanager.enable = true;
    hostName = "daimyo00";
    nameservers = [ "1.1.1.1" "8.8.8.8" ];
  };

  # WSL-specific settings
  wsl = {
    enable = true;
    defaultUser = "ryzengrind";
    nativeSystemd = true;
    wslConf = {
      automount.enabled = true;
      interop = {
        enabled = true;
        appendWindowsPath = false;
      };
      network = {
        generateHosts = true;
        generateResolvConf = lib.mkForce false;  # Use our own DNS settings
      };
    };
  };

  # Virtualization support for ML containers
  virtualisation = {
    docker = {
      enable = true;
      enableNvidia = true;  # Enable NVIDIA Container Toolkit
    };
    podman = {
      enable = true;
      enableNvidia = true;
    };
  };

  # System-level configuration
  system.stateVersion = "24.05";

  # Enable basic services
  services = {
    # DBus for various system services
    dbus = {
      enable = true;
      packages = [ pkgs.dconf ];
    };
  };
} 