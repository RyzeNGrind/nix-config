{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../base/wsl.nix
  ];

  # Host-specific configuration
  networking.hostName = "daimyo00";

  # WSL specialization
  specialisation = {
    cuda = {
      inheritParentConfig = true;
      configuration = {
        features.wsl.cuda.enable = true;
        environment.variables = {
          NVIDIA_DRIVER_CAPABILITIES = "compute,utility";
          NVIDIA_VISIBLE_DEVICES = "all";
          NVIDIA_REQUIRE_CUDA = "cuda>=12.0";
        };
      };
    };

    nogui = {
      inheritParentConfig = true;
      configuration = {
        features.wsl.gui.enable = false;
        environment.variables = {
          DISPLAY = lib.mkForce "";
          WAYLAND_DISPLAY = lib.mkForce "";
          XDG_RUNTIME_DIR = lib.mkForce "";
        };
      };
    };

    minimal = {
      inheritParentConfig = true;
      configuration = {
        features = {
          wsl = {
            gui.enable = false;
            cuda.enable = false;
          };
          nix-ld.enable = false;
          nix-index.enable = false;
        };
        services.openssh.enable = false;
        environment.systemPackages = with pkgs; [
          curl
          git
          vim
          wget
        ];
      };
    };
  };

  # Development tools
  environment.systemPackages = with pkgs; [
    # Version control
    git-lfs
    gh

    # Editors
    neovim
    vscode

    # Development tools
    gnumake
    gcc
    python3
    nodejs
    rustup

    # Container tools
    docker-compose
    lazydocker

    # System tools
    btop
    iotop
    ncdu
    tree
  ];

  # Container support
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    autoPrune.enable = true;
  };

  # Additional services
  services = {
    # VSCode server
    vscode-server.enable = true;

    # Automatic updates
    auto-upgrade = {
      enable = true;
      allowReboot = false;
      dates = "weekly";
    };
  };

  # System tweaks
  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
    "fs.inotify.max_user_watches" = 524288;
  };

  # Testing configuration
  testing = {
    enable = true;
    wsl = {
      specialisations = {
        cuda.enable = true;
        nogui.enable = true;
        minimal.enable = true;
      };
    };
  };
}
