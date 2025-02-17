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

  # Common programs
  programs = {
    nix-ld = {
      enable = true;
      package = pkgs.nix-ld-rs;
    };

    _1password = {
      enable = true;
      enableSshAgent = true;
      enableGitCredentialHelper = true;
      users = ["ryzengrind"];
      tokenFile = "/etc/1password/op-token";
    };
  };

  # Common user configuration
  users.users.ryzengrind = {
    isNormalUser = true;
    extraGroups = ["wheel" "docker" "networkmanager"];
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

        # Baremetal-specific configurations can be added here
        services.xserver = {
          enable = true;
          displayManager.gdm.enable = true;
          desktopManager.gnome.enable = true;
        };
      };
    };
  };

  # Testing configuration
  testing.suites.host = {
    enable = true;
    description = "Host-specific configuration tests";
    script = ''
      import pytest
      from nixostest import Machine

      def test_base_config(machine: Machine) -> None:
          """Test base configuration."""
          machine.succeed("test -f /etc/nixos/configuration.nix")
          machine.succeed("test -d /nix/store")

      def test_user_setup(machine: Machine) -> None:
          """Test user configuration."""
          machine.succeed("id ryzengrind")
          machine.succeed("groups ryzengrind | grep -q wheel")

      def test_packages(machine: Machine) -> None:
          """Test installed packages."""
          for pkg in ["git", "direnv", "htop"]:
              machine.succeed(f"type -P {pkg}")

      def test_locale(machine: Machine) -> None:
          """Test locale settings."""
          machine.succeed("locale | grep -q 'en_CA.UTF-8'")
          machine.succeed("timedatectl show | grep -q 'America/Toronto'")

      def test_specialisations(machine: Machine) -> None:
          """Test specialisation switching."""
          for spec in ["wsl-cuda", "wsl-nocuda", "baremetal"]:
              machine.succeed(f"nixos-rebuild test --specialisation {spec}")
    '';
  };
}
