{ config, lib, pkgs, ... }:

{
  options.profiles.dev = {
    enable = lib.mkEnableOption "Development environment profile";
    ide = lib.mkOption {
      type = lib.types.enum [ "vscode" "vscodium" "neovim" "cursor" ];
      default = "vscodium";
      description = "Primary IDE to use";
    };
    vscodeRemote = {
      enable = lib.mkEnableOption "VSCode Remote support";
      method = lib.mkOption {
        type = lib.types.enum [ "nix-ld" "patch" ];
        default = "nix-ld";
        description = "Method to enable VSCode Remote support (nix-ld or patch)";
      };
    };
    ml = {
      enable = lib.mkEnableOption "Machine Learning support";
      cudaSupport = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable CUDA support for ML frameworks";
      };
      tensorrt = {
        enable = lib.mkEnableOption "TensorRT support";
        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.cudaPackages.tensorrt;
          description = "TensorRT package to use";
        };
      };
    };
  };

  config = lib.mkIf config.profiles.dev.enable {
    environment.systemPackages = with pkgs; [
      # Version Control
      git
      git-lfs
      gh

      # Build tools
      gnumake
      cmake
      ninja

      # Development tools
      direnv
      nix-direnv
      wget # Required for VSCode Remote

      # Debugging and profiling
      gdb
      lldb
      strace
      ltrace

      # IDE and editor
      (lib.mkIf (config.profiles.dev.ide == "vscode") vscode)
      (lib.mkIf (config.profiles.dev.ide == "vscodium") 
        (vscode-with-extensions.override {
          vscode = vscodium;
          vscodeExtensions = with pkgs.vscode-extensions; [
            # Development
            ms-vscode.cpptools
            ms-python.python
            ms-vscode.cmake-tools
            
            # Remote Development
            ms-vscode-remote.remote-ssh
            
            # Git
            eamodio.gitlens
            
            # Nix
            bbenoist.nix
            jnoortheen.nix-ide
            arrterian.nix-env-selector
            
            # Theme and UI
            pkief.material-icon-theme
          ];
        })
      )
      (lib.mkIf (config.profiles.dev.ide == "neovim") neovim)

      # Language servers and formatters
      nil # Nix LSP
      nixpkgs-fmt
      alejandra
      statix # Nix static analysis

      # Python development
      (python3.withPackages (ps: with ps; [
        pip
        virtualenv
        poetry
        numpy
        pandas
        matplotlib
        scikit-learn
        jupyter
        ipython
        black
        pylint
        mypy
        pytest
        # PyTorch with CUDA if enabled
        (pytorch.override {
          cudaSupport = config.profiles.dev.ml.enable && config.profiles.dev.ml.cudaSupport;
        })
        torchvision
        torchaudio
        transformers
        pytorch-lightning
        tensorboard
        wandb  # Weights & Biases
        ray
        optuna
      ]))

      # CUDA development tools if ML is enabled
    ] ++ lib.optionals (config.profiles.dev.ml.enable && config.profiles.dev.ml.cudaSupport) ([
      cudaPackages.cuda_cudart
      cudaPackages.cuda_cupti
      cudaPackages.cuda_nvcc
    ] ++ lib.optionals config.profiles.dev.ml.tensorrt.enable [
      config.profiles.dev.ml.tensorrt.package
      cudaPackages.cudnn
    ] ++ [
      nvidia-docker
      nvtop
    ]);

    # VSCode Remote support configuration
    programs.nix-ld = lib.mkIf (config.profiles.dev.vscodeRemote.enable && config.profiles.dev.vscodeRemote.method == "nix-ld") {
      enable = true;
      package = pkgs.nix-ld-rs;
    };

    # If using patch method, include the vscode-remote-workaround module
    vscode-remote-workaround.enable = lib.mkIf (config.profiles.dev.vscodeRemote.enable && config.profiles.dev.vscodeRemote.method == "patch") true;

    # Development environment configuration
    programs = {
      direnv = {
        enable = true;
        nix-direnv.enable = true;
      };
    };

    # Nix development settings
    nix = {
      settings = {
        experimental-features = [ "nix-command" "flakes" "repl-flake" ];
        warn-dirty = false;
        keep-outputs = true;
        keep-derivations = true;
        # Optimizations for ML development
        auto-optimise-store = true;
        cores = 0;  # Use all cores
        max-jobs = "auto";
        # Increase timeout for large package downloads
        connect-timeout = 5;
        stalled-download-timeout = 90;
        timeout = 3600;
      };
    };

    # Enable NVIDIA support if ML is enabled
    hardware.nvidia = lib.mkIf (config.profiles.dev.ml.enable && config.profiles.dev.ml.cudaSupport) {
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      modesetting.enable = true;
      powerManagement = {
        enable = false;
        finegrained = false;
      };
      open = false;
      nvidiaSettings = true;
    };

    # Container support for ML
    virtualisation = lib.mkIf config.profiles.dev.ml.enable {
      docker = {
        enable = true;
        enableNvidia = config.profiles.dev.ml.cudaSupport;
      };
      podman = {
        enable = true;
        enableNvidia = config.profiles.dev.ml.cudaSupport;
      };
    };
  };
} 