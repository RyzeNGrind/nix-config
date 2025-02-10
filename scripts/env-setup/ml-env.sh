#!/usr/bin/env bash

# WSL2-specific NVIDIA setup
if [ -d "/usr/lib/wsl/lib" ]; then
  export NVIDIA_DRIVER_LIBRARY_PATH="/usr/lib/wsl/lib"
  export LD_LIBRARY_PATH="/usr/lib/wsl/lib:$NVIDIA_LIB_PATH:$NCURSES_LIB_PATH"
  export NVIDIA_DRIVER_CAPABILITIES="compute,utility"
  export NVIDIA_VISIBLE_DEVICES="all"
  export NVIDIA_REQUIRE_CUDA="cuda>=12.0"

  # Create symlinks for WSL NVIDIA libraries
  mkdir -p ~/.local/lib
  for lib in /usr/lib/wsl/lib/libcuda*; do
    if [ -f "$lib" ]; then
      ln -sf "$lib" ~/.local/lib/
    fi
  done
  export LD_LIBRARY_PATH="$HOME/.local/lib:$LD_LIBRARY_PATH"
fi

# CUDA setup
export CUDA_PATH="$CUDA_TOOLKIT_PATH"
export PATH="$CUDA_NVCC_PATH/bin:$NVIDIA_PATH/bin:$PATH"
export CUDA_HOME="$CUDA_PATH"
export XLA_FLAGS="--xla_gpu_cuda_data_dir=$CUDA_PATH"
export EXTRA_LDFLAGS="-L/lib -L$NVIDIA_PATH/lib"
export EXTRA_CCFLAGS="-I/usr/include"

# Create local bin directory for NVIDIA tools
mkdir -p ~/.local/bin
for cmd in nvidia-smi nvtop; do
  if command -v $cmd >/dev/null 2>&1; then
    ln -sf $(command -v $cmd) ~/.local/bin/
  fi
done
export PATH="$HOME/.local/bin:$PATH"

# Start fish shell
exec fish 