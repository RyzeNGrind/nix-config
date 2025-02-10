# modules/nixos/ml-env.nix
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.services.ml-env;
in
{
  options.services.ml-env = {
    enable = mkEnableOption "Machine Learning Environment";
    cudaVersion = mkOption {
      type = types.str;
      default = "12.0";
      description = "CUDA version to use";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      # CUDA packages
      cudaPackages.cuda_cudart
      cudaPackages.cuda_cupti
      cudaPackages.cudatoolkit
      cudaPackages.cudnn
      cudaPackages.cuda_nvcc
      # Python and monitoring tools
      python311
      python311Packages.pip
      python311Packages.virtualenv
      nvtopPackages.full
      nvidia-docker
    ];

    systemd.services.ml-env-setup = {
      description = "Setup Machine Learning Environment";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = config.wsl.defaultUser;
      };
      script = ''
        # Create directories
        mkdir -p ~/.local/{lib,bin}

        # WSL2-specific NVIDIA setup
        if [ -d "/usr/lib/wsl/lib" ]; then
          # Create symlinks for WSL NVIDIA libraries
          for lib in /usr/lib/wsl/lib/libcuda*; do
            if [ -f "$lib" ]; then
              ln -sf "$lib" ~/.local/lib/
            fi
          done

          # Create symlinks for NVIDIA tools
          for cmd in nvidia-smi nvtop; do
            if command -v $cmd >/dev/null 2>&1; then
              ln -sf $(command -v $cmd) ~/.local/bin/
            fi
          done
        fi

        # Create environment file
        cat > ~/.local/bin/activate-ml-env << 'EOF'
        #!/usr/bin/env bash
        export NVIDIA_DRIVER_LIBRARY_PATH="/usr/lib/wsl/lib"
        export LD_LIBRARY_PATH="/usr/lib/wsl/lib:${pkgs.linuxPackages.nvidia_x11}/lib:${pkgs.ncurses5}/lib:$HOME/.local/lib:$LD_LIBRARY_PATH"
        export NVIDIA_DRIVER_CAPABILITIES="compute,utility"
        export NVIDIA_VISIBLE_DEVICES="all"
        export NVIDIA_REQUIRE_CUDA="cuda>=${cfg.cudaVersion}"
        export CUDA_PATH="${pkgs.cudaPackages.cudatoolkit}"
        export PATH="${pkgs.cudaPackages.cuda_nvcc}/bin:${pkgs.linuxPackages.nvidia_x11}/bin:$HOME/.local/bin:$PATH"
        export CUDA_HOME="$CUDA_PATH"
        export XLA_FLAGS="--xla_gpu_cuda_data_dir=$CUDA_PATH"
        export EXTRA_LDFLAGS="-L/lib -L${pkgs.linuxPackages.nvidia_x11}/lib"
        export EXTRA_CCFLAGS="-I/usr/include"
        echo "Machine Learning Environment Activated"
        EOF

        # Make the activation script executable
        chmod +x ~/.local/bin/activate-ml-env
      '';
    };
  };
}
