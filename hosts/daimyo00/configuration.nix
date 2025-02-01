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
        cudaPackages = pkgs.cudaPackages_12_1;
      };
    };
  };

  nix.settings = {
    experimental-features = "nix-command flakes auto-allocate-uids";
    auto-optimise-store = true;
    trusted-users = [ "root" "ryzengrind" "@wheel" ];
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
  ];

  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    autoPrune.enable = true;
  };

  users.groups.docker.members = [ config.wsl.defaultUser ];
} 