{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ ];

  config = {
    # Common configuration for all formats
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    
    # Basic system configuration that should be common across formats
    boot.loader.systemd-boot.enable = lib.mkDefault true;
    boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;

    # Enable OpenSSH by default for remote access
    services.openssh = {
      enable = lib.mkDefault true;
      settings = {
        PermitRootLogin = lib.mkDefault "prohibit-password";
        PasswordAuthentication = lib.mkDefault false;
      };
    };

    # Basic networking configuration
    networking = {
      useDHCP = lib.mkDefault true;
      firewall = {
        enable = lib.mkDefault true;
        allowedTCPPorts = [ 22 ]; # SSH
      };
    };

    # System packages that should be available in all formats
    environment.systemPackages = lib.mkDefault (with pkgs; [
      vim
      git
      curl
      wget
    ]);

    # Format-specific configurations using nixos-generators' formats option
    formats = {
      virtualbox = lib.mkDefault {
        virtualisation.virtualbox.enable = true;
      };
      
      vmware = lib.mkDefault {
        virtualisation.vmware.enable = true;
      };
      
      qcow2 = lib.mkDefault {
        boot.loader.grub.enable = true;
        boot.loader.grub.device = "/dev/vda";
      };
      
      docker = lib.mkForce {
        virtualisation.docker.enable = true;
        services.openssh.enable = lib.mkForce false;
      };
      
      install-iso = lib.mkDefault {
        isoImage.makeEfiBootable = true;
        isoImage.makeUsbBootable = true;
      };
      
      sd-aarch64 = lib.mkDefault {
        hardware.raspberry-pi."4".enable = true;
      };
    };
  };
} 