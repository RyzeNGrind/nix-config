{ config, lib, pkgs, ... }:

{
  # Common WSL-specific system configurations
  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = false;

  # Disable services that don't make sense in WSL
  services.xserver.enable = false;
  services.xserver.desktopManager.gnome.enable = false;
  services.xserver.displayManager.gdm.enable = false;
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

  # WSL-specific environment variables
  environment.sessionVariables = {
    NIXOS_WSL = "1";
  };

  # Common system packages for WSL environments
  environment.systemPackages = with pkgs; [
    wslu  # WSL utilities
    wsl-open  # WSL browser opener
    wsl-clipboard  # WSL clipboard integration
  ];

  # WSL-specific security settings
  security.sudo.wheelNeedsPassword = false;  # Easier sudo access in WSL

  # WSL-specific networking settings
  networking = {
    useHostResolvConf = true;  # Use Windows DNS
    # Disable wait-online service as it doesn't make sense in WSL
    networkmanager.enable = true;
  };
} 