{
  config,
  pkgs,
  ...
}: {
  imports = [
    ../base/wsl.nix
  ];

  # Machine-specific configuration
  networking.hostName = "daimyo00";

  # Locale and time
  time.timeZone = "America/Toronto";
  i18n.defaultLocale = "en_CA.UTF-8";

  # Additional packages
  environment.systemPackages = with pkgs; [
    neofetch
    htop
    iotop
    pre-commit
  ];

  # Specialisations
  specialisation = {
    # Development environment
    dev = {
      inheritParentConfig = true;
      configuration = {
        environment.systemPackages = with pkgs; [
          # Development tools
          git-lfs
          gh
          direnv
          nixfmt
          alejandra
          statix

          # Languages and tools
          python3Full
          python3Packages.pip
          poetry
          rustup
          go
          nodejs
          yarn
        ];

        # Development services
        services = {
          postgresql = {
            enable = true;
            package = pkgs.postgresql_15;
          };
          redis.enable = true;
        };
      };
    };

    # CUDA development
    cuda = {
      inheritParentConfig = true;
      configuration = {
        wsl.cuda.enable = true;
        environment = {
          systemPackages = with pkgs; [
            cudaPackages.cudatoolkit
            cudaPackages.cudnn
            cudaPackages.tensorrt
          ];
          variables = {
            NVIDIA_DRIVER_CAPABILITIES = "compute,utility";
            NVIDIA_VISIBLE_DEVICES = "all";
            CUDA_PATH = "${pkgs.cudaPackages.cudatoolkit}";
          };
        };
      };
    };

    # GUI applications
    gui = {
      inheritParentConfig = true;
      configuration = {
        wsl.gui.enable = true;
        environment = {
          systemPackages = with pkgs; [
            firefox
            vscode
            gnome.gnome-terminal
          ];
          sessionVariables = {
            DISPLAY = ":0";
            WAYLAND_DISPLAY = "wayland-0";
            XDG_RUNTIME_DIR = "/run/user/1000";
            PULSE_SERVER = "unix:/run/user/1000/pulse/native";
          };
        };
        # X11 configuration
        services.xserver = {
          enable = true;
          displayManager.gdm.enable = true;
          desktopManager.gnome.enable = true;
        };
      };
    };

    # Container development
    containers = {
      inheritParentConfig = true;
      configuration = {
        virtualisation = {
          docker = {
            enable = true;
            enableNvidia = config.wsl.cuda.enable;
            extraOptions = "--dns 8.8.8.8";
          };
          podman = {
            enable = true;
            dockerCompat = true;
          };
        };
        environment.systemPackages = with pkgs; [
          docker-compose
          kubectl
          kubernetes-helm
          k9s
        ];
      };
    };
  };

  # Testing configuration
  testing = {
    enable = true;
    specialisation = {
      testScript = ''
        # Test base configuration
        machine.succeed("nixos-rebuild test")
        machine.succeed("test -f /etc/nixos/configuration.nix")

        # Test specialisations
        machine.succeed("nixos-rebuild test --specialisation dev")
        machine.succeed("nixos-rebuild test --specialisation cuda")
        machine.succeed("nixos-rebuild test --specialisation gui")
        machine.succeed("nixos-rebuild test --specialisation containers")

        # Verify services
        machine.succeed("systemctl is-active docker")
        machine.succeed("systemctl is-active postgresql")
        machine.succeed("systemctl is-active redis")

        # Test CUDA
        with subtest("CUDA support"):
            machine.succeed("nvidia-smi")
            machine.succeed("nvcc --version")

        # Test GUI
        with subtest("GUI support"):
            machine.wait_for_unit("display-manager.service")
            machine.wait_for_x()
      '';
    };
  };
}
