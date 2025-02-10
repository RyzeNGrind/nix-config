# Development shell configuration
{
  pkgs ? import <nixpkgs> { },
}:

let
  cudaPackages = pkgs.cudaPackages;
  inherit (cudaPackages) cudatoolkit;
  pythonEnv = pkgs.python3.withPackages (
    ps: with ps; [
      pip
      virtualenv
      (numpy.override { blas = pkgs.mkl; })
      pandas
      matplotlib
      scikit-learn
      (pytorch-bin.override {
        # Use binary package instead of building
        cudaSupport = true;
        cudatoolkit = cudatoolkit;
      })
      torchvision-bin
      torchaudio-bin
      transformers
      pytorch-lightning
      tensorboard
      wandb
      jupyter
      ipython
    ]
  );
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
        export LD_LIBRARY_PATH="${
          pkgs.lib.makeLibraryPath [
            "${cudaPackages.cuda_cudart}/lib"
            "${cudaPackages.cuda_cupti}/lib"
            "${cudaPackages.cuda_nvrtc}/lib"
            "${cudaPackages.libcublas}/lib"
            "${cudaPackages.cudnn}/lib"
            "${cudaPackages.tensorrt}/lib"
          ]
        }"
        export CUDA_HOME=${cudatoolkit}
        export CUDA_ROOT=${cudatoolkit}
        export CUDNN_PATH=${cudaPackages.cudnn}
        export EXTRA_LDFLAGS="-L/lib -L${cudatoolkit}/lib"
        export EXTRA_CCFLAGS="-I/usr/include"
        export PATH=${cudatoolkit}/bin:$PATH
        export PYTHONPATH="$PWD:$PYTHONPATH"
        export XLA_FLAGS="--xla_gpu_cuda_data_dir=${cudatoolkit}"
        echo "PyTorch + CUDA development environment loaded"
        echo "CUDA Version: $(nvcc --version | grep release | awk '{print $5}' | cut -c2-)"
        python -c "import torch; print(f'PyTorch CUDA available: {torch.cuda.is_available()}')"
  '';
}
