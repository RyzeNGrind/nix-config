{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.hardware.nvidia;
in {
  options.hardware.nvidia = {
    enable = mkEnableOption "NVIDIA driver and configuration";

    prime = {
      enable = mkEnableOption "NVIDIA PRIME support";
      intelBusId = mkOption {
        type = types.str;
        default = "PCI:0:2:0";
        description = "Bus ID of the Intel GPU";
      };
      nvidiaBusId = mkOption {
        type = types.str;
        default = "PCI:1:0:0";
        description = "Bus ID of the NVIDIA GPU";
      };
    };

    powerManagement = {
      enable = mkEnableOption "NVIDIA power management features";
      finegrained = mkEnableOption "Fine-grained power management";
    };
  };

  config = mkIf cfg.enable {
    hardware = {
      opengl = {
        enable = true;
        driSupport = true;
        driSupport32Bit = true;
        extraPackages = with pkgs; [
          vaapiVdpau
          libvdpau-va-gl
        ];
      };

      nvidia = {
        package = config.boot.kernelPackages.nvidiaPackages.stable;
        modesetting.enable = true;
        powerManagement = {
          inherit (cfg.powerManagement) enable finegrained;
        };
        prime = mkIf cfg.prime.enable {
          inherit (cfg.prime) intelBusId nvidiaBusId;
          offload = {
            enable = true;
            enableOffloadCmd = true;
          };
        };
      };
    };

    # Load nvidia driver
    services.xserver.videoDrivers = ["nvidia"];

    # Environment variables for NVIDIA
    environment.variables = {
      GBM_BACKEND = "nvidia-drm";
      LIBVA_DRIVER_NAME = "nvidia";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    };

    # Boot parameters for better NVIDIA support
    boot = {
      kernelParams = [
        "nvidia-drm.modeset=1" # Enable DRM kernel mode setting
      ];
      blacklistedKernelModules = ["nouveau"]; # Blacklist open-source driver
    };
  };
}
