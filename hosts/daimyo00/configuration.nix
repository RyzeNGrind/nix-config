# WSL-specific configuration for daimyo00
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.nixos-wsl.nixosModules.wsl
    # ../../modules/nixos/wsl.nix  # Commenting out to avoid conflicts
    ./cachix.nix
  ];

  nixpkgs = {
    config = {
      allowBroken = true;
      allowUnfree = true;
      cudaSupport = true;
      packageOverrides = pkgs: {
        cudaPackages = pkgs.cudaPackages_12_0;
      };
      /*
      permittedInsecurePackages = [
        "tensorrt-8.6.1.6"
        "tensorrt-10.8.0.43"
      ];
      */
    };
    /*
    overlays = [
      (import ../../overlays/tensorrt.nix)
    ];
    */
  };

  nix = {
    settings = {
      experimental-features = "nix-command flakes auto-allocate-uids";
      auto-optimise-store = true;
      trusted-users = ["root" "ryzengrind" "@wheel"];
      max-jobs = "auto";
      cores = 0;
      keep-outputs = true;
      keep-derivations = true;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
    optimise = {
      automatic = true;
      dates = ["weekly"];
    };
  };

  programs.nix-ld = {
    enable = true;
    package = pkgs.nix-ld-rs; # only for NixOS 24.05
  };

  networking.hostName = "daimyo00";
  networking.networkmanager.enable = true;
  systemd.services.NetworkManager-wait-online.enable = false;

  time.timeZone = "America/Toronto";
  i18n.defaultLocale = "en_CA.UTF-8";

  users.users.ryzengrind = {
    hashedPassword = "$6$VOP1Yx5OUXwpOFaG$tVWf3Ai0.kzXpblhnatoeHHZb1xGKUuSEEQO79y1efrSyXR0sGmvFjo7oHbZBuQgZ3NFZi0MahU5hbyzsIwqq.";
    isNormalUser = true;
    extraGroups = ["wheel" "docker" "audio" "networkmanager"];
  };

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = true;
    };
  };

  system.stateVersion = "24.05";
  system.autoUpgrade = {
    enable = true;
    allowReboot = false;
    channel = "https://channels.nixos.org/nixos-24.05";
  };

  # WSL-specific NVIDIA configuration
  hardware = {
    nvidia = {
      # Modesetting is required for most modern NVIDIA cards
      modesetting.enable = true;
      # Power management features (disabled for WSL)
      powerManagement.enable = false;
      powerManagement.finegrained = false;
      # Enable the Nvidia settings menu
      nvidiaSettings = true;
      # Use the stable driver package
      package = config.boot.kernelPackages.nvidiaPackages.beta; # [source](https://github.com/lutris/docs/blob/2b116519c5b67254733234f36ab33a60f14f1358/InstallingDrivers.md?plain=1#L184)
      # Open source kernel module (for Turing and newer GPUs)
      open = false; # Set to true only if you have a Turing or newer GPU
    };

    # Updated OpenGL/Graphics configuration
    graphics = {
      enable = true; # Enables OpenGL
      enable32Bit = true; # For 32-bit support
      extraPackages = with pkgs; [
        nvidia-vaapi-driver
        # Add additional OpenGL/CUDA support packages
        cudaPackages.cuda_nvcc # Replace cuda_gl
        cudaPackages.cuda_cuobjdump # Replace cuda_cccl
      ];
    };

    nvidia-container-toolkit.enable = true;
  };

  # Docker configuration for NVIDIA
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    autoPrune.enable = true;
    daemon.settings = {
      features.cdi = true;
      runtimes.nvidia = {
        path = "${pkgs.nvidia-container-toolkit}/bin/nvidia-container-runtime";
        runtimeArgs = [];
      };
    };
  };

  # WSL configuration
  wsl = {
    enable = true;
    defaultUser = "ryzengrind";
    docker-desktop.enable = true;
    nativeSystemd = true;
    startMenuLaunchers = true;
    wslConf = {
      automount = {
        enabled = true;
        options = "metadata,umask=22,fmask=11,uid=1000,gid=100";
        root = "/mnt";
      };
      network = {
        generateHosts = true;
        generateResolvConf = true;
        hostname = "daimyo00";
      };
      interop = {
        appendWindowsPath = false;
      };
    };
    extraBin = with pkgs; [
      {src = "${coreutils}/bin/cat";}
      {src = "${coreutils}/bin/whoami";}
      {src = "${su}/bin/groupadd";}
      {src = "${su}/bin/usermod";}
    ];
  };

  # WSL-specific NVIDIA environment setup
  environment.variables = {
    NVIDIA_DRIVER_LIBRARY_PATH = "/usr/lib/wsl/lib";
    NVIDIA_DRIVER_CAPABILITIES = "compute,graphics,utility,video";
    NVIDIA_VISIBLE_DEVICES = "all";
    NVIDIA_REQUIRE_CUDA = "cuda>=12.0";
    # Update LD_LIBRARY_PATH to include all necessary paths
    LD_LIBRARY_PATH = lib.mkForce (lib.concatStringsSep ":" [
      "/usr/lib/wsl/lib"
      "${pkgs.linuxPackages.nvidia_x11}/lib"
      "${pkgs.cudaPackages.cuda_cudart}/lib"
      "${pkgs.cudaPackages.cudatoolkit}/lib"
      "${pkgs.cudaPackages.cuda_nvcc}/lib" # Updated from cuda_gl
      "${pkgs.cudaPackages.cuda_cuobjdump}/lib" # Updated from cuda_cccl
      "/run/opengl-driver/lib"
      "$HOME/.local/lib"
    ]);
    # Add additional CUDA environment variables
    CUDA_PATH = "${pkgs.cudaPackages.cudatoolkit}";
    EXTRA_LDFLAGS = "-L/usr/lib/wsl/lib -L${pkgs.linuxPackages.nvidia_x11}/lib";
    EXTRA_CCFLAGS = "-I/usr/include";
    CUDA_HOME = "${pkgs.cudaPackages.cudatoolkit}";
    XLA_FLAGS = "--xla_gpu_cuda_data_dir=${pkgs.cudaPackages.cudatoolkit}";
  };

  # Add necessary kernel modules and blacklist nouveau
  boot = {
    initrd.kernelModules = ["nvidia"];
    blacklistedKernelModules = ["nouveau"];
    extraModulePackages = [config.boot.kernelPackages.nvidia_x11];
  };

  # System packages
  environment.systemPackages = with pkgs; [
    # WSL-specific packages
    wslu
    wsl-open
    wsl-vpnkit
    # CUDA packages
    cudaPackages.cuda_cudart
    cudaPackages.cuda_cupti
    cudaPackages.cuda_nvrtc
    cudaPackages.libcublas
    cudaPackages.cudnn
    cudaPackages.cudatoolkit
    cudaPackages.cuda_nvcc # Updated from cuda_gl
    cudaPackages.cuda_cuobjdump # Updated from cuda_cccl
    # Monitoring tools
    nvtopPackages.full
    clinfo # Added for OpenGL verification
    glxinfo # Added for additional graphics info
    # Basic utilities
    curl
    jq
    git
    wget
    neofetch
    pre-commit
  ];

  users.groups.docker.members = [config.wsl.defaultUser];

  # Add a systemd service to setup NVIDIA symlinks
  systemd.services.nvidia-wsl-setup = {
    description = "Setup NVIDIA WSL environment";
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # Create local lib directory
      mkdir -p /home/${config.wsl.defaultUser}/.local/lib

      # Create symlinks for WSL NVIDIA libraries
      for lib in /usr/lib/wsl/lib/libcuda*; do
        if [ -f "$lib" ]; then
          ln -sf "$lib" /home/${config.wsl.defaultUser}/.local/lib/
        fi
      done

      # Set permissions
      chown -R ${config.wsl.defaultUser}:users /home/${config.wsl.defaultUser}/.local/lib
    '';
  };
}
