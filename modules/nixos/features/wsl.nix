# WSL features module
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.core.features;
in {
  imports = [
    inputs.nixos-wsl.nixosModules.wsl
  ];

  options.core.features = with lib; {
    wsl = {
      enable = mkEnableOption "WSL support";
      gui.enable = mkEnableOption "WSL GUI support";
      cuda.enable = mkEnableOption "WSL CUDA support";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.wsl.enable {
      # Enable upstream WSL module
      wsl = {
        enable = true;
        nativeSystemd = true;
        startMenuLaunchers = true;
        # Default WSL configuration
        wslConf = {
          automount = {
            enabled = true;
            options = "metadata,umask=22,fmask=11";
            mountFsTab = true;
            root = "/mnt";
          };
          network = {
            generateHosts = true;
            generateResolvConf = true;
          };
          interop = {
            enabled = true;
            appendWindowsPath = false;
          };
        };
      };

      # Common WSL optimizations
      boot = {
        isContainer = true;
        loader = {
          systemd-boot.enable = false;
          efi.canTouchEfiVariables = false;
        };
      };

      # Disable unnecessary services
      systemd.services = {
        "serial-getty@ttyS0".enable = false;
        "serial-getty@hvc0".enable = false;
        "getty@tty1".enable = false;
        "autovt@".enable = false;
      };
    })

    (lib.mkIf cfg.wsl.gui.enable {
      environment.systemPackages = with pkgs; [
        wslu
        wsl-vpnkit
        wsl-open
        xorg.xhost
      ];
      environment.sessionVariables = {
        DISPLAY = "$(grep nameserver /etc/resolv.conf | cut -d ' ' -f 2):0";
        LIBGL_ALWAYS_INDIRECT = "1";
        WAYLAND_DISPLAY = "wayland-0";
        XDG_RUNTIME_DIR = "/run/user/$(id -u)";
        PULSE_SERVER = "tcp:$(grep nameserver /etc/resolv.conf | cut -d ' ' -f 2)";
      };
    })

    (lib.mkIf cfg.wsl.cuda.enable {
      environment.systemPackages = with pkgs; [
        cudatoolkit
        cudaPackages.cudnn
        linuxPackages.nvidia_x11
      ];
      environment.sessionVariables = {
        CUDA_PATH = "${pkgs.cudatoolkit}";
        LD_LIBRARY_PATH = "${pkgs.linuxPackages.nvidia_x11}/lib:${pkgs.cudatoolkit}/lib:${pkgs.cudaPackages.cudnn}/lib";
      };
    })
  ];
}
