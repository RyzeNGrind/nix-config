{
  config,
  pkgs,
  lib,
  ...
}: {
  # Import core modules
  imports = [
    ../../modules/core/features.nix
    ../../modules/services/wsl.nix
  ];

  # Base WSL configuration
  wsl = {
    enable = true;
    nativeSystemd = true;
    defaultUser = "ryzengrind";
    startMenuLaunchers = true;

    # Default automount configuration
    automountPath = "/mnt";
    wslConf = {
      automount = {
        enabled = true;
        mountFsTab = true;
        root = "/mnt";
        options = "metadata,uid=1000,gid=100,umask=22,fmask=11";
      };

      # Default network configuration
      network = {
        generateHosts = lib.mkForce true;
        generateResolvConf = lib.mkForce true;
      };
      interop = {
        enabled = true;
        appendWindowsPath = false;
      };
    };

    # Extra binaries
    extraBin = with pkgs; [
      {src = "${coreutils}/bin/cat";}
      {src = "${coreutils}/bin/whoami";}
      {src = "${su}/bin/groupadd";}
      {src = "${su}/bin/usermod";}
    ];
  };

  # Enable WSL service
  services.wsl = {
    enable = true;
    automount.enable = true;
    network.generateHosts = true;
  };

  # Disable firewall in WSL since it's not needed
  networking.firewall.enable = lib.mkForce false;

  # Base system configuration
  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes" "auto-allocate-uids"];
      auto-optimise-store = true;
      trusted-users = ["root" "ryzengrind" "@wheel"];
      max-jobs = "auto";
      cores = 0;
      keep-outputs = true;
      keep-derivations = true;
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
    optimise = {
      automatic = true;
      dates = ["weekly"];
    };
  };

  # Base system packages
  environment.systemPackages = with pkgs; [
    # Core utilities
    coreutils
    curl
    git
    vim
    wget

    # WSL utilities
    wslu
    wsl-open
    wsl-vpnkit

    # Development tools
    gnumake
    gcc
    python3
  ];

  # Base system configuration
  system = {
    stateVersion = "24.05";
  };

  # Base security configuration
  security = {
    sudo.wheelNeedsPassword = false;
    rtkit.enable = true;
  };

  # Base user configuration
  users.users.ryzengrind = {
    isNormalUser = true;
    extraGroups = ["wheel" "docker" "audio" "networkmanager"];
    hashedPassword = "$6$VOP1Yx5OUXwpOFaG$tVWf3Ai0.kzXpblhnatoeHHZb1xGKUuSEEQO79y1efrSyXR0sGmvFjo7oHbZBuQgZ3NFZi0MahU5hbyzsIwqq.";
  };

  # Base networking configuration
  networking = {
    networkmanager.enable = true;
  };

  # Base service configuration
  services = {
    # SSH for remote access
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
    };

    # Time synchronization
    timesyncd.enable = true;
  };

  # Base virtualisation configuration
  virtualisation = {
    docker = {
      enable = true;
      autoPrune = {
        enable = true;
        dates = "weekly";
      };
    };
  };

  # Base specialisation configuration
  specialisation = {
    # GUI support
    gui = {
      inheritParentConfig = true;
      configuration = {
        wsl.gui.enable = true;
        environment.sessionVariables = {
          DISPLAY = ":0";
          WAYLAND_DISPLAY = "wayland-0";
          XDG_RUNTIME_DIR = "/run/user/1000";
          PULSE_SERVER = "unix:/run/user/1000/pulse/native";
        };
      };
    };

    # CUDA support
    cuda = {
      inheritParentConfig = true;
      configuration = {
        wsl.cuda.enable = true;
        environment.variables = {
          NVIDIA_DRIVER_CAPABILITIES = "compute,utility";
          NVIDIA_VISIBLE_DEVICES = "all";
          CUDA_PATH = "${pkgs.cudaPackages.cudatoolkit}";
        };
      };
    };
  };

  # Add docker group
  users.groups.docker.members = [config.wsl.defaultUser];
}
