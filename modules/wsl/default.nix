# WSL-specific configuration module
{
  config,
  lib,
  pkgs,
  ...
}: {
  options.wsl = {
    enable = lib.mkEnableOption "WSL-specific configuration";

    cuda = {
      enable = lib.mkEnableOption "CUDA support in WSL";
    };
  };

  config = lib.mkIf config.wsl.enable {
    # WSL-specific system configuration
    system.stateVersion = lib.mkDefault "24.05";

    # Enable systemd
    systemd.enable = true;

    # WSL-specific packages
    environment.systemPackages = with pkgs; [
      wslu # WSL utilities
      wsl-open # WSL file opener
    ];

    # WSL-specific services
    services = {
      # Enable OpenSSH for remote access
      openssh = {
        enable = true;
        settings = {
          PermitRootLogin = "no";
          PasswordAuthentication = false;
        };
      };
    };

    # WSL-specific networking
    networking = {
      useHostResolvConf = true;
      useDHCP = false;
    };

    # CUDA configuration if enabled
    hardware.nvidia = lib.mkIf config.wsl.cuda.enable {
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      modesetting.enable = true;
    };
  };
}
