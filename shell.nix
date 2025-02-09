# Development shell configuration
{ pkgs ? import <nixpkgs> { } }:

let
  cudaPackages = pkgs.cudaPackages_12_8;  # Use latest CUDA version
  pythonEnv = pkgs.python3.withPackages (ps: with ps; [
    pip
    virtualenv
    (numpy.override { blas = pkgs.mkl; })
    pandas
    matplotlib
    scikit-learn
    (pytorch-bin.override {  # Use binary package instead of building
      cudaSupport = true;
      cudatoolkit = cudaPackages.cudatoolkit;
    })
    torchvision-bin
    torchaudio-bin
    transformers
    pytorch-lightning
    tensorboard
    wandb
    jupyter
    ipython
  ]);
in
pkgs.mkShell {
  name = "ml-dev-shell";
  buildInputs = with pkgs; [
    pythonEnv
    cudaPackages.cuda_cudart
    cudaPackages.cuda_cupti
    cudaPackages.cuda_nvrtc
    cudaPackages.libcublas
    cudaPackages.cudnn
    cudaPackages.tensorrt
    nvidia-docker
    git
    gh
  ];

  shellHook = ''
    export CUDA_PATH="${cudaPackages.cuda_cudart}"
    export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath [
      "${cudaPackages.cuda_cudart}/lib"
      "${cudaPackages.cuda_cupti}/lib"
      "${cudaPackages.cuda_nvrtc}/lib"
      "${cudaPackages.libcublas}/lib"
      "${cudaPackages.cudnn}/lib"
      "${cudaPackages.tensorrt}/lib"
    ]}"
    export CUDA_HOME=${cudaPackages.cudatoolkit}
    export CUDA_ROOT=${cudaPackages.cudatoolkit}
    export CUDNN_PATH=${cudaPackages.cudnn}
    export EXTRA_LDFLAGS="-L/lib -L${cudaPackages.cudatoolkit}/lib"
    export EXTRA_CCFLAGS="-I/usr/include"
    export PATH=${cudaPackages.cudatoolkit}/bin:$PATH
    export PYTHONPATH="$PWD:$PYTHONPATH"
    export XLA_FLAGS="--xla_gpu_cuda_data_dir=${cudaPackages.cudatoolkit}"
    echo "PyTorch + CUDA development environment loaded"
    echo "CUDA Version: $(nvcc --version | grep release | awk '{print $5}' | cut -c2-)"
    python -c "import torch; print(f'PyTorch CUDA available: {torch.cuda.is_available()}')"
  '';
} 