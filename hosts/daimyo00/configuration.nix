# WSL-specific configuration for daimyo00
{ config, lib, pkgs, inputs, ... }:

{
  imports = [ 
    inputs.nixos-wsl.nixosModules.wsl
    ../../modules/nixos/wsl.nix  # Common WSL configuration module
    ./cachix.nix
  ];

  nixpkgs = {
    config = {
      allowBroken = true;
      allowUnfree = true;
      cudaSupport = true;
      packageOverrides = pkgs: {
        inherit (pkgs) cudaPackages_11_8 cudaPackages_12_0;
        # Set default CUDA version for TensorRT 10.8
        cudaPackages = pkgs.cudaPackages_11_8;  # Use stable CUDA version
      };
      permittedInsecurePackages = [
        "tensorrt-8.6.1.6"
        "tensorrt-10.8.0.43"
      ];
    };
    overlays = [
      (import ../../overlays/tensorrt.nix)
    ];
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
    ];
  };

  environment.systemPackages = with pkgs; [
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
    tensorrt.tensorrt_10_8_cuda11
    tensorrt.tensorrt_10_8_cuda12
    tensorrt.tensorrt_8_6_cuda11
    tensorrt.tensorrt_8_6_cuda12
    pre-commit
  ];

  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    autoPrune.enable = true;
  };

  users.groups.docker.members = [ config.wsl.defaultUser ];

  # Add environment variables for CUDA and TensorRT
  environment.variables = {
    CUDA_PATH = "${pkgs.cudaPackages.cuda_cudart}";
    LD_LIBRARY_PATH = lib.makeLibraryPath [
      "${pkgs.cudaPackages.cuda_cudart}/lib"
      "${pkgs.cudaPackages.cuda_cupti}/lib"
      "${pkgs.cudaPackages.cuda_nvrtc}/lib"
      "${pkgs.cudaPackages.libcublas}/lib"
      "${pkgs.cudaPackages.cudnn}/lib"
      "${pkgs.cudaPackages.tensorrt}/lib"
    ];
  };
} 