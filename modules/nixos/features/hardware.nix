# Hardware features module
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.core.features;
in {
  options.core.features = with lib; {
    hardware = {
      nvidia.enable = mkEnableOption "NVIDIA driver and CUDA support";
      amd.enable = mkEnableOption "AMD driver and compute support";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.hardware.nvidia.enable {
      services.xserver.videoDrivers = ["nvidia"];
      hardware.nvidia = {
        package = config.boot.kernelPackages.nvidiaPackages.stable;
        modesetting.enable = true;
        powerManagement.enable = true;
        open = false;
      };
      hardware.opengl = {
        enable = true;
        driSupport = true;
        driSupport32Bit = true;
      };
      environment.systemPackages = with pkgs; [
        cudatoolkit
        nvtop
      ];
    })

    (lib.mkIf cfg.hardware.amd.enable {
      services.xserver.videoDrivers = ["amdgpu"];
      hardware.opengl = {
        enable = true;
        driSupport = true;
        driSupport32Bit = true;
        extraPackages = with pkgs; [
          rocm-opencl-icd
          rocm-opencl-runtime
          amdvlk
        ];
      };
      environment.systemPackages = with pkgs; [
        rocm-smi
        radeontop
      ];
    })
  ];
}
