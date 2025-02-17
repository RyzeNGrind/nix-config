# Host-specific home configuration for daimyo with specialisation support
{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ../../modules/home-manager/wsl.nix # Import our WSL module
  ];

  # Basic home-manager settings
  home = {
    username = "ryzengrind";
    homeDirectory = "/home/ryzengrind";
    stateVersion = "24.05";

    # Shell integration for 1Password
    sessionVariables = {
      SSH_AUTH_SOCK = "${config.home.homeDirectory}/.1password/agent.sock";
    };

    # Common packages across all specialisations
    packages = with pkgs; [
      # Development tools
      git
      gh
      direnv
      nix-direnv
      pre-commit
      nodePackages.prettier
      black # Python formatting
      alejandra # Nix formatting
      statix # Nix static analysis
      deadnix # Finding dead code
      shellcheck # Shell script analysis

      # Build tools
      gcc
      gnumake
      cargo
      rustc

      # System tools
      htop
      btop
      iotop

      # Network tools
      curl
      wget
      dig
      whois

      # Terminal utilities
      tmux
      fzf
      ripgrep
      fd
      jq
      yq
    ];
  };

  # Consolidated program configurations
  programs = {
    # Enable home-manager
    home-manager.enable = true;

    # 1Password shell integration
    _1password = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
    };

    # Git configuration
    git = {
      enable = true;
      userName = "ryzengrind";
      userEmail = "ryzengrind@daimyo.local";
      extraConfig = {
        init.defaultBranch = "main";
        pull.rebase = true;
        push.autoSetupRemote = true;
      };
      package = pkgs.git;
    };

    bash = {
      enable = true;
      enableCompletion = true;
      shellAliases = {
        ll = "ls -la";
        ".." = "cd ..";
        "..." = "cd ../..";
        # Specialisation-aware rebuild commands
        "rebuild-cuda" = "sudo nixos-rebuild switch --flake .#daimyo --specialisation wsl-cuda";
        "rebuild-nocuda" = "sudo nixos-rebuild switch --flake .#daimyo --specialisation wsl-nocuda";
        "rebuild-baremetal" = "sudo nixos-rebuild switch --flake .#daimyo --specialisation baremetal";
        update = "nix flake update";
      };
      # Add specialisation detection to bashrc
      initExtra = ''
        # Detect current specialisation
        if [[ -e /run/current-system/specialisation ]]; then
          current_spec=$(readlink /run/current-system/specialisation)
          PS1="\[\033[01;32m\][\u@\h:''${current_spec##*/}]\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "
        else
          PS1="\[\033[01;32m\][\u@\h]\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "
        fi

        # Set environment based on specialisation
        if [[ "''${current_spec}" == *"wsl-cuda"* ]]; then
          # CUDA environment setup
          export CUDA_PATH="${pkgs.cudaPackages.cudatoolkit}"
          export CUDA_HOME="$CUDA_PATH"
          export PATH="$PATH:$CUDA_HOME/bin"
          export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$CUDA_HOME/lib64"
        fi
      '';
    };

    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    vim = {
      enable = true;
      extraConfig = ''
        set number
        set relativenumber
        set expandtab
        set tabstop=2
        set shiftwidth=2
        syntax on
      '';
    };

    # Add VSCode with specialisation-specific extensions
    vscode = {
      enable = true;
      extensions = with pkgs.vscode-extensions;
        [
          # Common extensions
          bbenoist.nix
          jnoortheen.nix-ide
          mkhl.direnv
          ms-vscode.cpptools
          ms-python.python

          # Conditional CUDA extensions
          (lib.mkIf (config.system.nixos.tags or [] == ["wsl-cuda"])
            nvidia.nsight-vscode-edition)
        ]
        ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
          # Add any marketplace extensions here
        ];
    };
  };

  # Specialisation-specific configurations
  config = lib.mkMerge [
    # Base configuration
    {}

    # CUDA specialisation
    (lib.mkIf (config.system.nixos.tags or [] == ["wsl-cuda"]) {
      home.packages = with pkgs; [
        cudaPackages.cuda_nvcc
        cudaPackages.cuda_cupti
        cudaPackages.cudnn
        nvtop
      ];
    })

    # Baremetal specialisation
    (lib.mkIf (config.system.nixos.tags or [] == ["baremetal"]) {
      home.packages = with pkgs; [
        # GUI applications
        firefox
        chromium
        vlc
        # System monitoring
        gnome.gnome-system-monitor
        powertop
      ];

      # Desktop-specific configurations
      dconf.settings = {
        "org/gnome/desktop/interface" = {
          enable-hot-corners = false;
          gtk-theme = "Adwaita-dark";
        };
      };
    })
  ];

  # Enable fonts in home-manager
  fonts.fontconfig.enable = true;

  # Testing configuration
  test.stubs.homeConfiguration = {
    enable = true;
    tests = {
      common = {
        description = "Test common configuration";
        script = ''
          import pytest
          from pathlib import Path

          def test_basic_setup(home):
              """Test basic home configuration."""
              assert home.username == "ryzengrind"
              assert Path(home.homeDirectory).exists()

          def test_git_config(home):
              """Test git configuration."""
              gitconfig = Path(home.homeDirectory) / ".gitconfig"
              assert gitconfig.exists()
              assert "ryzengrind@daimyo.local" in gitconfig.read_text()

          def test_common_packages(home):
              """Test common packages are installed."""
              for cmd in ["git", "direnv", "tmux", "fzf"]:
                  assert home.command_exists(cmd)
        '';
      };

      cuda = {
        description = "Test CUDA specialisation";
        script = ''
          def test_cuda_env(home):
              """Test CUDA environment."""
              if home.specialisation == "wsl-cuda":
                  assert "CUDA_PATH" in home.env
                  assert "CUDA_HOME" in home.env
                  assert home.command_exists("nvcc")
        '';
      };

      baremetal = {
        description = "Test baremetal specialisation";
        script = ''
          def test_gui_packages(home):
              """Test GUI packages."""
              if home.specialisation == "baremetal":
                  assert home.command_exists("firefox")
                  assert home.command_exists("vlc")
        '';
      };
    };
  };
}
