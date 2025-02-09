# WSL-specific configuration for daimyo00
{ config, lib, pkgs, inputs, ... }:

{
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
        cudaPackages = pkgs.cudaPackages_12_0;  # Use latest CUDA version
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
      trusted-users = [ "root" "ryzengrind" "@wheel" ];
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
      dates = [ "weekly" ];
    };
  };

  networking.hostName = "daimyo00";
  networking.networkmanager.enable = true;
  systemd.services.NetworkManager-wait-online.enable = false;

  time.timeZone = "America/Toronto";
  i18n.defaultLocale = "en_CA.UTF-8";

  users.users.ryzengrind = {
    hashedPassword = "$6$VOP1Yx5OUXwpOFaG$tVWf3Ai0.kzXpblhnatoeHHZb1xGKUuSEEQO79y1efrSyXR0sGmvFjo7oHbZBuQgZ3NFZi0MahU5hbyzsIwqq.";
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" "audio" "networkmanager" ];
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
      { src = "${coreutils}/bin/cat"; }
      { src = "${coreutils}/bin/whoami"; }
      { src = "${su}/bin/groupadd"; }
      { src = "${su}/bin/usermod"; }
      { src = "${linuxPackages.nvidia_x11}/bin/nvidia-smi"; }
      { src = "${nvtopPackages.full}/bin/nvtop"; }
    ];
  };

  environment.systemPackages = with pkgs; [
    # WSL-specific packages
    wslu
    wsl-open
    wsl-vpnkit
    curl
    git
    wget
    neofetch
    nvtopPackages.full
    cudaPackages.cuda_cudart
    cudaPackages.cuda_cupti
    cudaPackages.cuda_nvrtc
    cudaPackages.libcublas
    cudaPackages.cudnn
    # TensorRT packages for different versions and CUDA versions
    # tensorrt.tensorrt_10_8_cuda11
    # tensorrt.tensorrt_10_8_cuda12
    # tensorrt.tensorrt_8_6_cuda11
    # tensorrt.tensorrt_8_6_cuda12
    pre-commit
  ];
  # WSL-specific NVIDIA configuration
  hardware.nvidia = {
    # Let WSL module handle the package
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
  };

  # OpenGL configuration
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
    extraPackages = with pkgs; [
      nvidia-vaapi-driver
    ];
  };

  # NVIDIA Container Runtime configuration
  hardware.nvidia-container-toolkit.enable = true;
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    autoPrune.enable = true;
    daemon.settings = {
      features.cdi = true;  # Enable CDI for GPU support
      runtimes = {
        nvidia = {
          path = "${pkgs.nvidia-container-toolkit}/bin/nvidia-container-runtime";
          runtimeArgs = [];
        };
      };
    };
  };

  # WSL-specific NVIDIA environment setup
  environment.variables = {
    NVIDIA_DRIVER_LIBRARY_PATH = "/usr/lib/wsl/lib";
    NVIDIA_DRIVER_CAPABILITIES = "compute,utility,graphics,video";
    NVIDIA_VISIBLE_DEVICES = "all";
    NVIDIA_REQUIRE_CUDA = "cuda>=12.0";
    # WSL2-specific paths
    LD_LIBRARY_PATH = lib.mkForce (lib.concatStringsSep ":" [
      "/usr/lib/wsl/lib"  # WSL NVIDIA libraries
      "${pkgs.linuxPackages.nvidia_x11}/lib"
      "${pkgs.ncurses5}/lib"
      "${pkgs.cudaPackages.cuda_cudart}/lib"
      "${pkgs.cudaPackages.cuda_cupti}/lib"
      "${pkgs.cudaPackages.cuda_nvrtc}/lib"
      "${pkgs.cudaPackages.libcublas}/lib"
      "${pkgs.cudaPackages.cudnn}/lib"
    ]);
    PATH = lib.mkForce (lib.makeBinPath [
      "${pkgs.linuxPackages.nvidia_x11}/bin"
      "${pkgs.nvtopPackages.full}/bin"
      "/usr/lib/wsl/lib"
    ] + ":$PATH");
  };

  users.groups.docker.members = [ config.wsl.defaultUser ];
} 