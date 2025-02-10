# WSL configuration with CUDA support
{
  config,
  lib,
  pkgs,
  ...
}: {
  # Import WSL base configuration
  imports = [
    ../base/wsl.nix
  ];

  # CUDA-specific configuration
  nixpkgs.config = {
    cudaSupport = true;
    packageOverrides = pkgs: {
      cudaPackages = pkgs.cudaPackages_12_0;
    };
  };

  # NVIDIA configuration
  hardware = {
    nvidia = {
      # Modesetting is required for most modern NVIDIA cards
      modesetting.enable = true;
      # Power management features (disabled for WSL)
      powerManagement.enable = false;
      powerManagement.finegrained = false;
      # Enable the Nvidia settings menu
      nvidiaSettings = true;
      # Use the stable driver package
      package = config.boot.kernelPackages.nvidiaPackages.beta;
      # Open source kernel module (for Turing and newer GPUs)
      open = false;
    };

    # Updated OpenGL/Graphics configuration
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        nvidia-vaapi-driver
        cudaPackages.cuda_nvcc
        cudaPackages.cuda_cuobjdump
      ];
    };

    nvidia-container-toolkit.enable = true;
  };

  # Docker configuration for NVIDIA
  virtualisation.docker = {
    enableNvidia = true;
    daemon.settings = {
      features.cdi = true;
      runtimes.nvidia = {
        path = "${pkgs.nvidia-container-toolkit}/bin/nvidia-container-runtime";
        runtimeArgs = [];
      };
    };
  };

  # CUDA environment setup
  environment = {
    variables = {
      NVIDIA_DRIVER_LIBRARY_PATH = "/usr/lib/wsl/lib";
      NVIDIA_DRIVER_CAPABILITIES = "compute,graphics,utility,video";
      NVIDIA_VISIBLE_DEVICES = "all";
      NVIDIA_REQUIRE_CUDA = "cuda>=12.0";
      CUDA_PATH = "${pkgs.cudaPackages.cudatoolkit}";
      EXTRA_LDFLAGS = "-L/usr/lib/wsl/lib -L${pkgs.linuxPackages.nvidia_x11}/lib";
      EXTRA_CCFLAGS = "-I/usr/include";
      CUDA_HOME = "${pkgs.cudaPackages.cudatoolkit}";
      XLA_FLAGS = "--xla_gpu_cuda_data_dir=${pkgs.cudaPackages.cudatoolkit}";
      # Update LD_LIBRARY_PATH to include all necessary paths
      LD_LIBRARY_PATH = lib.mkForce (lib.concatStringsSep ":" [
        "/usr/lib/wsl/lib"
        "${pkgs.linuxPackages.nvidia_x11}/lib"
        "${pkgs.cudaPackages.cuda_cudart}/lib"
        "${pkgs.cudaPackages.cudatoolkit}/lib"
        "${pkgs.cudaPackages.cuda_nvcc}/lib"
        "${pkgs.cudaPackages.cuda_cuobjdump}/lib"
        "/run/opengl-driver/lib"
        "$HOME/.local/lib"
      ]);
    };

    # CUDA-specific packages
    systemPackages = with pkgs; [
      # CUDA packages
      cudaPackages.cuda_cudart
      cudaPackages.cuda_cupti
      cudaPackages.cuda_nvrtc
      cudaPackages.libcublas
      cudaPackages.cudnn
      cudaPackages.cudatoolkit
      cudaPackages.cuda_nvcc
      cudaPackages.cuda_cuobjdump
      # Monitoring tools
      nvtopPackages.full
      clinfo
      glxinfo
    ];
  };

  # Add a systemd service to setup NVIDIA symlinks
  systemd.services.nvidia-wsl-setup = {
    description = "Setup NVIDIA WSL environment";
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # Create local lib directory
      mkdir -p /home/${config.wsl.defaultUser}/.local/lib

      # Create symlinks for WSL NVIDIA libraries
      for lib in /usr/lib/wsl/lib/libcuda*; do
        if [ -f "$lib" ]; then
          ln -sf "$lib" /home/${config.wsl.defaultUser}/.local/lib/
        fi
      done

      # Set permissions
      chown -R ${config.wsl.defaultUser}:users /home/${config.wsl.defaultUser}/.local/lib
    '';
  };

  # Testing configuration
  testing = {
    enable = true;
    testScript = ''
      # Test CUDA environment
      with subtest("CUDA environment"):
          machine.succeed("nvidia-smi")
          machine.succeed("nvcc --version")
          machine.succeed("test -n \"$CUDA_PATH\"")
          machine.succeed("test -n \"$CUDA_HOME\"")

      # Test NVIDIA libraries
      with subtest("NVIDIA libraries"):
          machine.succeed("test -d /usr/lib/wsl/lib")
          machine.succeed("ls -l /usr/lib/wsl/lib/libcuda*")
          machine.succeed("ldconfig -p | grep -q cuda")

      # Test Docker NVIDIA runtime
      with subtest("Docker NVIDIA runtime"):
          machine.succeed("docker run --rm --gpus all nvidia/cuda:12.0-base nvidia-smi")
          machine.succeed("docker run --rm --gpus all nvidia/cuda:12.0-base nvcc --version")
    '';
  };
}
