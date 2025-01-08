{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ ];

  options = {
    formatConfigs = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          formatAttr = lib.mkOption {
            type = lib.types.str;
            description = "The attribute that contains the build output";
          };
          fileExtension = lib.mkOption {
            type = lib.types.str;
            description = "The file extension for the output";
          };
        };
      });
      default = {};
      description = "Format configurations for different output types";
    };
  };

  config = {
    # Default format configurations
    formatConfigs = {
      # VM formats
      virtualbox = {
        formatAttr = "virtualBoxOVA";
        fileExtension = ".ova";
      };
      vmware = {
        formatAttr = "vmware";
        fileExtension = ".vmx";
      };
      qcow2 = {
        formatAttr = "qcow2";
        fileExtension = ".qcow2";
      };

      # Container formats
      docker = {
        formatAttr = "dockerImage";
        fileExtension = ".tar.gz";
      };

      # Installation media
      iso = {
        formatAttr = "isoImage";
        fileExtension = ".iso";
      };
      sd-aarch64 = {
        formatAttr = "sdImage";
        fileExtension = ".img";
      };
    };

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
    environment.systemPackages = with pkgs; [
      vim
      git
      curl
      wget
    ];
  };
} 