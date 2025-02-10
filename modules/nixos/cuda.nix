# modules/nixos/cuda.nix
{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.hardware.nvidia.cuda;
in
{
  options.hardware.nvidia.cuda = {
    enable = mkEnableOption "NVIDIA CUDA support";
    package = mkOption {
      type = types.package;
      default = pkgs.cudaPackages.cudatoolkit;
      description = "The CUDA package to use";
    };
    environmentVariables = mkOption {
      type = types.attrs;
      default = { };
      description = "Additional environment variables for CUDA";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      cudaPackages.cuda_cudart
      cudaPackages.cuda_cupti
      cudaPackages.cudatoolkit
      cudaPackages.cudnn
      cudaPackages.cuda_nvcc
      nvtopPackages.full
    ];

    environment.variables = {
      CUDA_PATH = "${cfg.package}";
      NVIDIA_DRIVER_LIBRARY_PATH = mkIf config.wsl.enable "/usr/lib/wsl/lib";
      NVIDIA_DRIVER_CAPABILITIES = "compute,graphics,utility,video";
      NVIDIA_VISIBLE_DEVICES = "all";
      NVIDIA_REQUIRE_CUDA = "cuda>=12.0";
      CUDA_HOME = "${cfg.package}";
      XLA_FLAGS = "--xla_gpu_cuda_data_dir=${cfg.package}";
      EXTRA_LDFLAGS = "-L/lib -L${pkgs.linuxPackages.nvidia_x11}/lib";
      EXTRA_CCFLAGS = "-I/usr/include";
    } // cfg.environmentVariables;

    # WSL-specific systemd service for NVIDIA setup
    systemd.services.nvidia-wsl-setup = mkIf config.wsl.enable {
      description = "Setup NVIDIA WSL environment";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        mkdir -p /home/${config.wsl.defaultUser}/.local/{lib,bin}
        
        # Create symlinks for WSL NVIDIA libraries
        for lib in /usr/lib/wsl/lib/libcuda*; do
          if [ -f "$lib" ]; then
            ln -sf "$lib" /home/${config.wsl.defaultUser}/.local/lib/
          fi
        done

        # Create symlinks for NVIDIA tools
        for cmd in nvidia-smi nvtop; do
          if command -v $cmd >/dev/null 2>&1; then
            ln -sf $(command -v $cmd) /home/${config.wsl.defaultUser}/.local/bin/
          fi
        done

        chown -R ${config.wsl.defaultUser}:users /home/${config.wsl.defaultUser}/.local
      '';
    };
  };
} 