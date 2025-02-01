# WSL-specific NixOS configuration
{ config, lib, pkgs, ... }:

{
  # Common WSL-specific system configurations
  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = false;

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
    };
    
    pathsToLink = [ "/libexec" ];

    systemPackages = with pkgs; [
      wslu  # WSL utilities including wslview
      wsl-open  # WSL browser opener
      xclip  # X11 clipboard tool
      xsel   # X11 selection tool
    ];
  };

  # WSL-specific security settings
  security.sudo.wheelNeedsPassword = false;  # Easier sudo access in WSL

  # WSL-specific networking settings
  networking = {
    useHostResolvConf = true;  # Use Windows DNS
    # Disable wait-online service as it doesn't make sense in WSL
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
        generateResolvConf = false;
      };
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