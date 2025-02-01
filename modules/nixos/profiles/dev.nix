{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.profiles.dev;
in {
  options.profiles.dev = {
    enable = mkEnableOption "Development environment profile";
    ide = mkOption {
      type = types.enum [ "vscode" "vscodium" "neovim" "cursor" ];
      default = "vscodium";
      description = "Primary IDE to use";
    };
    vscodeRemote = {
      enable = mkEnableOption "VSCode Remote support";
      method = mkOption {
        type = types.enum [ "nix-ld" "patch" ];
        default = "nix-ld";
        description = "Method to enable VSCode Remote support (nix-ld or patch)";
      };
    };
    ml = {
      enable = mkEnableOption "Machine Learning support";
      cudaSupport = mkOption {
        type = types.bool;
        default = true;
        description = "Enable CUDA support for ML frameworks";
      };
      pytorch = {
        enable = mkEnableOption "PyTorch support";
        package = mkOption {
          type = types.package;
          default = pkgs.python3Packages.pytorch.override {
            cudaSupport = config.profiles.dev.ml.cudaSupport;
            cudaPackages = pkgs.cudaPackages;
          };
          description = "PyTorch package to use";
        };
      };
    };
  };

  config = mkIf cfg.enable {
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
      (mkIf (cfg.ide == "vscode") vscode)
      (mkIf (cfg.ide == "vscodium") 
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
      (mkIf (cfg.ide == "neovim") neovim)

      # Language servers and formatters
      nil # Nix LSP
      nixpkgs-fmt
      alejandra
      statix # Nix static analysis

      # Python ML stack with known working versions
      (python3.withPackages (ps: with ps; [
        pip
        virtualenv
        poetry
        (numpy.override { blas = pkgs.mkl; })
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
        (mkIf cfg.ml.pytorch.enable cfg.ml.pytorch.package)
        (mkIf cfg.ml.pytorch.enable torchvision)
        (mkIf cfg.ml.pytorch.enable torchaudio)
        transformers
        pytorch-lightning
        tensorboard
        wandb
        ray
        optuna
      ]))

      # CUDA development tools
    ] ++ optionals (cfg.ml.enable && cfg.ml.cudaSupport) [
      cudaPackages.cuda_cudart
      cudaPackages.cuda_cupti
      cudaPackages.cuda_nvcc
      cudaPackages.cudnn
      nvidia-docker
      nvtopPackages.full
    ];

    # VSCode Remote support configuration
    programs.nix-ld = mkIf (cfg.vscodeRemote.enable && cfg.vscodeRemote.method == "nix-ld") {
      enable = true;
      package = pkgs.nix-ld-rs;
    };

    # If using patch method, include the vscode-remote-workaround module
    vscode-remote-workaround.enable = mkIf (cfg.vscodeRemote.enable && cfg.vscodeRemote.method == "patch") true;

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
        # Increase resource limits for ML workloads
        sandbox = true;
        trusted-users = [ "root" "@wheel" ];
        # Cache settings for better performance
        substituters = [
          "https://cache.nixos.org"
          "https://cuda-maintainers.cachix.org"
        ];
        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
        ];
      };
    };

    # Enable NVIDIA support if ML is enabled
    hardware.nvidia = mkIf (cfg.ml.enable && cfg.ml.cudaSupport) {
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
    virtualisation = mkIf cfg.ml.enable {
      docker = {
        enable = true;
        enableNvidia = cfg.ml.cudaSupport;
      };
      podman = {
        enable = true;
        enableNvidia = cfg.ml.cudaSupport;
      };
    };
  };
} 