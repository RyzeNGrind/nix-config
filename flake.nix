{
  description = "Your new nix config";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    # You can access packages and modules from different nixpkgs revs
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NixOS-WSL
    nixos-wsl.url = "github:nix-community/nixos-wsl";
    
    # Hardware configuration
    nixos-hardware.url = "github:nixos/nixos-hardware";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, nixos-wsl, ... } @ inputs: let
    inherit (self) outputs;
    systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
    forAllSystems = nixpkgs.lib.genAttrs systems;
    # Add this new overlay to make unstable packages available
    overlayUnstable = final: prev: {
      unstable = import nixpkgs-unstable {
        system = prev.system;
        config.allowUnfree = true;
      };
    };
  in {
    # Your custom packages and modifications
    devShells = forAllSystems (system: let
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          cudaSupport = true;
        };
      };
    in {
      default = pkgs.mkShell {
        buildInputs = with pkgs; [
          nixfmt
          statix
        ];
      };
      
      ml = (pkgs.buildFHSEnv {
        name = "cuda-ml-env";
        targetPkgs = pkgs: (with pkgs; [
          linuxPackages.nvidia_x11
          libGLU libGL
          xorg.libXi xorg.libXmu freeglut
          xorg.libXext xorg.libX11 xorg.libXv xorg.libXrandr zlib 
          ncurses5 stdenv.cc binutils
          ffmpeg
          fish
          micromamba
          # CUDA packages
          cudaPackages.cuda_cudart
          cudaPackages.cuda_cupti
          cudaPackages.cudatoolkit
          cudaPackages.cudnn
          cudaPackages.cuda_nvcc
          # Python and monitoring tools
          python311
          python311Packages.pip
          python311Packages.virtualenv
          nvtopPackages.full
          nvidia-docker
          # Development tools
          git
          curl
          wget
        ]);

        profile = ''
          # WSL2-specific NVIDIA setup
          if [ -d "/usr/lib/wsl/lib" ]; then
            export NVIDIA_DRIVER_LIBRARY_PATH="/usr/lib/wsl/lib"
            export LD_LIBRARY_PATH="/usr/lib/wsl/lib:${pkgs.linuxPackages.nvidia_x11}/lib:${pkgs.ncurses5}/lib"
            
            # Create symlinks for WSL NVIDIA libraries if they don't exist
            mkdir -p ~/.local/lib
            for lib in /usr/lib/wsl/lib/libcuda*; do
              if [ -f "$lib" ]; then
                ln -sf "$lib" ~/.local/lib/
              fi
            done
            export LD_LIBRARY_PATH="$HOME/.local/lib:$LD_LIBRARY_PATH"
          fi
          
          # CUDA setup
          export CUDA_PATH="${pkgs.cudaPackages.cudatoolkit}"
          export PATH="${pkgs.cudaPackages.cuda_nvcc}/bin:${pkgs.linuxPackages.nvidia_x11}/bin:$PATH"
          
          # NVIDIA environment variables
          export NVIDIA_DRIVER_CAPABILITIES="compute,utility,graphics,video"
          export NVIDIA_VISIBLE_DEVICES="all"
          export NVIDIA_REQUIRE_CUDA="cuda>=12.0"
          
          # CUDA development setup
          export EXTRA_LDFLAGS="-L/lib -L${pkgs.linuxPackages.nvidia_x11}/lib"
          export EXTRA_CCFLAGS="-I/usr/include"
          export CUDA_HOME="$CUDA_PATH"
          export XLA_FLAGS="--xla_gpu_cuda_data_dir=$CUDA_PATH"
          
          # Create local bin directory for NVIDIA tools
          mkdir -p ~/.local/bin
          for cmd in nvidia-smi nvtop; do
            if command -v $cmd >/dev/null 2>&1; then
              ln -sf $(command -v $cmd) ~/.local/bin/
            fi
          done
          export PATH="$HOME/.local/bin:$PATH"
        '';

        runScript = "fish";
      }).env;
    });
    packages = forAllSystems (system: import ./pkgs {
      inherit system;
      pkgs = nixpkgs.legacyPackages.${system};
    });
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);
    overlays = import ./overlays { inherit inputs; } // {
      unstable = overlayUnstable;
    };
    nixosModules = import ./modules/nixos;

    # NixOS configuration entrypoint
    nixosConfigurations = {
      # WSL configuration
      daimyo00 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs outputs; };
        modules = [
          # Core modules
          ./hosts/daimyo00/configuration.nix
          
          # Global configuration
          {
            nixpkgs.config = {
              allowBroken = true;
              allowUnfree = true;
            };
            nix = {
              settings = {
                substituters = [
                  "https://cache.nixos.org"
                  "https://cuda-maintainers.cachix.org"
                  "https://nix-community.cachix.org"
                ];
                trusted-public-keys = [
                  "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
                  "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
                  "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
                ];
                accept-flake-config = true;
              };
            };
          }
          
          # Home Manager module
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.ryzengrind = import ./hosts/daimyo00/home.nix;
              extraSpecialArgs = { inherit inputs outputs; };
            };
          }
        ];
      };

      # No CUDA/TensorRT configuration
      daimyo00-nocuda = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          # WSL module
          inputs.nixos-wsl.nixosModules.wsl

          # Base configuration
          ({ pkgs, lib, ... }: {
            # Basic system configuration
            system.stateVersion = "24.05";

            # System configuration
            nixpkgs = {
              config = {
                allowUnfree = true;
                allowBroken = true;
                # Explicitly disable CUDA
                cudaSupport = lib.mkForce false;
                cudaCapabilities = lib.mkForce [];
              };
              # Ensure no CUDA overlays
              overlays = [];
            };

            # Disable all NVIDIA/CUDA related features
            hardware = {
              nvidia = {
                package = lib.mkForce null;
                modesetting.enable = lib.mkForce false;
              };
              nvidia-container-toolkit.enable = lib.mkForce false;
              opengl.enable = lib.mkForce false;
            };

            # Explicitly disable WSL CUDA features
            wsl = {
              enable = true;
              defaultUser = "ryzengrind";
              docker-desktop.enable = true;
              nativeSystemd = true;
              startMenuLaunchers = true;
              wslConf = {
                automount = {
                  enabled = true;
                  options = "metadata,umask=22,fmask=11,uid=1000,gid=100";
                  root = "/mnt";
                };
                network = {
                  generateHosts = true;
                  generateResolvConf = true;
                  hostname = "daimyo00";
                };
                interop = {
                  appendWindowsPath = false;
                };
              };
              extraBin = with pkgs; [
                { src = "${coreutils}/bin/cat"; }
                { src = "${coreutils}/bin/whoami"; }
                { src = "${su}/bin/groupadd"; }
                { src = "${su}/bin/usermod"; }
              ];
            };

            # Disable NVIDIA container runtime in Docker instead
            virtualisation.docker = {
              enable = true;
              enableOnBoot = true;
              autoPrune.enable = true;
              # Disable NVIDIA runtime
              enableNvidia = lib.mkForce false;
              extraOptions = "--add-runtime none=runc";
            };

            # Environment variables to prevent CUDA detection
            environment.variables = {
              CUDA_PATH = lib.mkForce "";
              LD_LIBRARY_PATH = lib.mkForce "";
              NVIDIA_DRIVER_CAPABILITIES = lib.mkForce "";
              NVIDIA_VISIBLE_DEVICES = lib.mkForce "none";
            };

            nix = {
              settings = {
                experimental-features = [ "nix-command" "flakes" "auto-allocate-uids" ];
                auto-optimise-store = true;
                trusted-users = [ "root" "ryzengrind" "@wheel" ];
                max-jobs = "auto";
                cores = 0;
                keep-outputs = true;
                keep-derivations = true;
                # Remove CUDA cache
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
                dates = [ "weekly" ];
              };
            };

            # Network configuration
            networking = {
              hostName = "daimyo00";
              networkmanager.enable = true;
            };
            systemd.services.NetworkManager-wait-online.enable = false;

            # Locale and time
            time.timeZone = "America/Toronto";
            i18n.defaultLocale = "en_CA.UTF-8";

            # User configuration
            users.users.ryzengrind = {
              hashedPassword = "$6$VOP1Yx5OUXwpOFaG$tVWf3Ai0.kzXpblhnatoeHHZb1xGKUuSEEQO79y1efrSyXR0sGmvFjo7oHbZBuQgZ3NFZi0MahU5hbyzsIwqq.";
              isNormalUser = true;
              extraGroups = [ "wheel" "docker" "audio" "networkmanager" ];
            };

            # SSH configuration
            services.openssh = {
              enable = true;
              settings = {
                PermitRootLogin = "yes";
                PasswordAuthentication = true;
              };
            };

            # System packages (no CUDA packages)
            environment.systemPackages = with pkgs; [
              curl
              git
              wget
              neofetch
              pre-commit
            ];
          })

          # Home Manager configuration
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.ryzengrind = import ./hosts/daimyo00/home.nix;
              extraSpecialArgs = { inherit inputs; };
            };
          }
        ];
      };

      # Minimal test configuration
      daimyo00-test = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          # Bare minimum NixOS configuration
          ({ pkgs, lib, ... }: {
            # Basic system configuration
            system.stateVersion = "24.05";
            
            nixpkgs = {
              config = {
                allowUnfree = true;
                allowBroken = false;
              };
              # Disable all custom overlays for testing
              overlays = [];
            };
            
            # Minimal nix settings
            nix.settings = {
              substituters = [ "https://cache.nixos.org" ];
              trusted-public-keys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ];
              accept-flake-config = true;
              experimental-features = [ "nix-command" "flakes" ];
            };

            # Basic system packages
            environment.systemPackages = with pkgs; [
              git
              vim
              pre-commit
            ];

            # Basic user configuration
            users.users.ryzengrind = {
              isNormalUser = true;
              extraGroups = [ "wheel" ];
              initialPassword = "changeme";
            };

            # WSL-specific settings
            wsl = {
              enable = true;
              defaultUser = "ryzengrind";
              nativeSystemd = true;
            };
          })

          # Include WSL module
          nixos-wsl.nixosModules.wsl
        ];
      };
    };

    # Standalone home-manager configuration entrypoint
    homeConfigurations = {
      "ryzengrind@daimyo00" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        extraSpecialArgs = { inherit inputs outputs; };
        modules = [
          ./hosts/daimyo00/home.nix
        ];
      };
    };
  };
}
