{ pkgs }:

{
  # Environment setup function
  setupCudaEnv = {
    wslNvidiaSetup = ''
      if [ -d "/usr/lib/wsl/lib" ]; then
        export NVIDIA_DRIVER_LIBRARY_PATH="/usr/lib/wsl/lib"
        export LD_LIBRARY_PATH="/usr/lib/wsl/lib:${pkgs.linuxPackages.nvidia_x11}/lib:${pkgs.ncurses5}/lib"
        export NVIDIA_DRIVER_CAPABILITIES="compute,utility"
        export NVIDIA_VISIBLE_DEVICES="all"
        export NVIDIA_REQUIRE_CUDA="cuda>=12.0"
      fi
    '';

    cudaSetup = ''
      export CUDA_PATH="${pkgs.cudaPackages.cudatoolkit}"
      export PATH="${pkgs.cudaPackages.cuda_nvcc}/bin:${pkgs.linuxPackages.nvidia_x11}/bin:$PATH"
      export CUDA_HOME="$CUDA_PATH"
      export XLA_FLAGS="--xla_gpu_cuda_data_dir=$CUDA_PATH"
    '';

    devSetup = ''
      export EXTRA_LDFLAGS="-L/lib -L${pkgs.linuxPackages.nvidia_x11}/lib"
      export EXTRA_CCFLAGS="-I/usr/include"
    '';
  };

  # Function to create symlinks
  createSymlinks = ''
    mkdir -p ~/.local/{lib,bin}
    
    # WSL NVIDIA library symlinks
    if [ -d "/usr/lib/wsl/lib" ]; then
      for lib in /usr/lib/wsl/lib/libcuda*; do
        if [ -f "$lib" ]; then
          ln -sf "$lib" ~/.local/lib/
        fi
      done
      export LD_LIBRARY_PATH="$HOME/.local/lib:$LD_LIBRARY_PATH"
    fi

    # NVIDIA tools symlinks
    for cmd in nvidia-smi nvtop; do
      if command -v $cmd >/dev/null 2>&1; then
        ln -sf $(command -v $cmd) ~/.local/bin/
      fi
    done
    export PATH="$HOME/.local/bin:$PATH"
  '';
} 