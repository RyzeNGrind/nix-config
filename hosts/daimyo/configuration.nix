# Host-specific configuration for daimyo
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    # Import base configurations
    ../base/default.nix
    ../base/wsl.nix
    # Import hardware configurations from nixos-hardware
    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-gpu-nvidia
  ];

  # Base configuration shared across all specialisations
  networking.hostName = "daimyo";
  time.timeZone = "America/Toronto";
  i18n.defaultLocale = "en_CA.UTF-8";

  # Common Nix settings
  nix = {
    settings = {
      experimental-features = "nix-command flakes auto-allocate-uids";
      auto-optimise-store = true;
      trusted-users = ["root" "ryzengrind" "@wheel"];
      max-jobs = "auto";
      cores = 0;
      keep-outputs = true;
      keep-derivations = true;
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

  # Common programs using standard NixOS modules
  programs = {
    nix-ld = {
      enable = true;
      package = pkgs.nix-ld-rs;
    };

    # Hyprland-related programs (disabled by default, enabled in baremetal)
    hyprland.enable = false;

    # 1Password CLI
    _1password = {
      enable = true;
      package = pkgs._1password;
    };

    # 1Password GUI with polkit integration
    _1password-gui = {
      enable = true;
      polkitPolicyOwners = ["ryzengrind"]; # Required for proper authorization
      package = pkgs._1password-gui;
    };

    firefox = {
      enable = true;
      package = pkgs.firefox;
    };

    chromium = {
      enable = true;
    };

    fish = {
      enable = true;
      package = pkgs.fish;
    };

    # Configure Git to use 1Password
    git = {
      enable = true;
      package = pkgs.git;
      config = {
        init.defaultBranch = "main";
        pull.rebase = true;
        credential.helper = "${pkgs._1password-gui}/share/1password/op-credential-store";
        user.signingkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPL6GOQ1zpvnxJK0Mz+vUHgEd0f/sDB0q3pa38yHHEsC";
        commit.gpgsign = true;
        gpg = {
          format = "ssh";
          ssh.program = "${pkgs._1password-gui}/share/1password/op-ssh-sign";
        };
      };
    };
  };

  # Common user configuration
  users.users.ryzengrind = {
    isNormalUser = true;
    extraGroups = ["wheel" "docker" "networkmanager" "onepassword"];
    hashedPassword = "$6$VOP1Yx5OUXwpOFaG$tVWf3Ai0.kzXpblhnatoeHHZb1xGKUuSEEQO79y1efrSyXR0sGmvFjo7oHbZBuQgZ3NFZi0MahU5hbyzsIwqq.";
  };

  # Common system packages
  environment.systemPackages = with pkgs; [
    # Development tools
    git
    git-lfs
    gh
    direnv
    nixfmt
    alejandra
    statix

    # System tools
    htop
    iotop
    neofetch
    pre-commit
    curl
    jq
    wget
  ];

  # Specialisations
  specialisation = {
    wsl-cuda = {
      inheritParentConfig = true;
      configuration = {
        system.nixos.tags = ["wsl-cuda"];
        features.desktop = {
          enable = false;
          hyprland.enable = false;
        };
        programs = {
          hyprland.enable = false;
        };
        nixpkgs.config = {
          allowUnfree = true;
          cudaSupport = true;
          packageOverrides = pkgs: {
            cudaPackages = pkgs.cudaPackages_12_0;
          };
        };

        # NVIDIA configuration
        hardware = {
          nvidia = {
            modesetting.enable = true;
            powerManagement.enable = false;
            powerManagement.finegrained = false;
            nvidiaSettings = true;
            package = config.boot.kernelPackages.nvidiaPackages.beta;
            open = false;
          };

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

        # Docker with NVIDIA
        virtualisation.docker = {
          enable = true;
          enableOnBoot = true;
          autoPrune.enable = true;
          daemon.settings = {
            features.cdi = true;
            runtimes.nvidia = {
              path = "${pkgs.nvidia-container-toolkit}/bin/nvidia-container-runtime";
              runtimeArgs = [];
            };
          };
        };

        # NVIDIA environment variables
        environment.variables = {
          NVIDIA_DRIVER_LIBRARY_PATH = "/usr/lib/wsl/lib";
          NVIDIA_DRIVER_CAPABILITIES = "compute,graphics,utility,video";
          NVIDIA_VISIBLE_DEVICES = "all";
          NVIDIA_REQUIRE_CUDA = "cuda>=12.0";
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
          CUDA_PATH = "${pkgs.cudaPackages.cudatoolkit}";
          CUDA_HOME = "${pkgs.cudaPackages.cudatoolkit}";
          EXTRA_LDFLAGS = "-L/usr/lib/wsl/lib -L${pkgs.linuxPackages.nvidia_x11}/lib";
          EXTRA_CCFLAGS = "-I/usr/include";
          XLA_FLAGS = "--xla_gpu_cuda_data_dir=${pkgs.cudaPackages.cudatoolkit}";
        };

        # Additional CUDA packages
        environment.systemPackages = with pkgs; [
          cudaPackages.cuda_cudart
          cudaPackages.cuda_cupti
          cudaPackages.cuda_nvrtc
          cudaPackages.libcublas
          cudaPackages.cudnn
          cudaPackages.cudatoolkit
          cudaPackages.cuda_nvcc
          cudaPackages.cuda_cuobjdump
          nvtopPackages.full
          clinfo
          glxinfo
        ];

        # NVIDIA kernel setup
        boot = {
          initrd.kernelModules = ["nvidia"];
          blacklistedKernelModules = ["nouveau"];
          extraModulePackages = [config.boot.kernelPackages.nvidia_x11];
        };

        # NVIDIA WSL setup service
        systemd.services.nvidia-wsl-setup = {
          description = "Setup NVIDIA WSL environment";
          wantedBy = ["multi-user.target"];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          script = ''
            mkdir -p /home/${config.wsl.defaultUser}/.local/lib
          '';
        };
      };
    };

    wsl-nocuda = {
      inheritParentConfig = true;
      configuration = {
        system.nixos.tags = ["wsl-nocuda"];
        features.desktop = {
          enable = false;
          hyprland.enable = false;
        };
        programs = {
          hyprland.enable = false;
        };
        nixpkgs.config = {
          allowUnfree = true;
          cudaSupport = false;
        };

        # Basic Docker without NVIDIA
        virtualisation.docker = {
          enable = true;
          enableOnBoot = true;
          autoPrune.enable = true;
        };
      };
    };

    baremetal = {
      inheritParentConfig = true;
      configuration = {
        system.nixos.tags = ["baremetal"];
        features.desktop = {
          enable = true;
          hyprland.enable = true;
          gnome.enable = true;
        };
        # Enable Hyprland-related programs in baremetal
        programs = {
          hyprland = {
            enable = true;
            xwayland.enable = true;
          };
        };
        # Enable Hyprland-related home-manager programs in baremetal
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          users.ryzengrind = {
            wayland.windowManager.hyprland = {
              enable = true;
              systemd.enable = true;
              xwayland.enable = true;
            };
          };
        };
        # Baremetal-specific configurations
        services.xserver = {
          enable = true;
          displayManager.gdm.enable = true;
          desktopManager.gnome.enable = true;
        };
      };
    };
  };

  # Ensure polkit is available
  security.polkit.enable = true;

  # Create required directories with proper permissions
  systemd.tmpfiles.rules = [
    "d /etc/1password 0755 root onepassword"
  ];
}
