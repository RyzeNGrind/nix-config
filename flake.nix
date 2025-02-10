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

    # Pre-commit hooks
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NixOS-WSL
    nixos-wsl.url = "github:nix-community/nixos-wsl";

    # Hardware configuration
    nixos-hardware.url = "github:nixos/nixos-hardware";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    home-manager,
    nixos-wsl,
    pre-commit-hooks,
    ...
  } @ inputs: let
    inherit (self) outputs;
    # Only build for Linux systems
    linuxSystems = ["x86_64-linux" "aarch64-linux"];
    # For packages that can build on any system
    allSystems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
    forAllSystems = nixpkgs.lib.genAttrs allSystems;
    # Add this new overlay to make unstable packages available
    overlayUnstable = _: prev: {
      unstable = import nixpkgs-unstable {
        inherit (prev) system;
        config.allowUnfree = true;
      };
    };
  in {
    # Add checks for pre-commit hooks
    checks = forAllSystems (system: {
      pre-commit-check = pre-commit-hooks.lib.${system}.run {
        src = ./.;
        hooks = {
          alejandra = {
            enable = true;
            name = "alejandra";
            entry = "${nixpkgs.legacyPackages.${system}.alejandra}/bin/alejandra";
            files = "\\.nix$";
            language = "system";
          };
          deadnix = {
            enable = true;
            name = "deadnix";
            entry = "${nixpkgs.legacyPackages.${system}.deadnix}/bin/deadnix";
            files = "\\.nix$";
            language = "system";
          };
          statix = {
            enable = true;
            name = "statix";
            entry = "${nixpkgs.legacyPackages.${system}.statix}/bin/statix check";
            files = "\\.nix$";
            language = "system";
          };
          prettier = {
            enable = true;
            name = "prettier";
            entry = "${nixpkgs.legacyPackages.${system}.nodePackages.prettier}/bin/prettier --write";
            files = "\\.(md|yml|yaml|json)$";
            language = "system";
          };
        };
      };
    });

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
        buildInputs = with pkgs;
          [
            alejandra
            deadnix
            statix
            nodePackages.prettier
            pre-commit
          ]
          ++ self.checks.${system}.pre-commit-check.enabledPackages;

        shellHook = ''
          ${self.checks.${system}.pre-commit-check.shellHook}

          echo "🛠️  Available tools:"
          echo "  🔧 alejandra - Nix code formatter"
          echo "    alejandra <file>     Format a single file"
          echo "    alejandra .          Format all files in directory"
          echo ""
          echo "  🔍 deadnix - Find dead code in .nix files"
          echo "    deadnix <file>       Analyze a single file"
          echo "    deadnix -e           Edit files in-place"
          echo ""
          echo "  ✨ statix - Lints and suggestions for Nix code"
          echo "    statix check         Check for issues"
          echo "    statix fix           Auto-fix common issues"
          echo ""
          echo "  💅 prettier - Code formatter"
          echo "    prettier <file>      Format a single file"
          echo "    prettier --write .   Format all supported files"
          echo ""
          echo "  🔄 pre-commit - Git hooks manager"
          echo "    pre-commit run       Run hooks on staged files"
          echo "    pre-commit run -a    Run hooks on all files"
          echo ""
        '';
      };
    });

    # Rest of your flake outputs...
    packages = forAllSystems (system: let
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          cudaSupport = system == "x86_64-linux" || system == "aarch64-linux";
        };
      };

      # Create empty derivation with explicit structure
      emptyDrv = derivation {
        name = "empty";
        inherit system;
        builder = "${pkgs.bash}/bin/bash";
        args = ["-c" "mkdir -p $out"];
      };

      # Create TensorRT package based on system support
      tensorrtPkg =
        if (builtins.elem system linuxSystems)
        then (pkgs.callPackage ./pkgs/tensorrt {inherit (pkgs) cudaPackages;})
        else emptyDrv;
    in {
      default = tensorrtPkg;
      tensorrt = tensorrtPkg;
    });

    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);
    overlays =
      import ./overlays {inherit inputs;}
      // {
        unstable = overlayUnstable;
      };
    nixosModules = import ./modules/nixos;

    # NixOS configuration entrypoint
    nixosConfigurations = {
      # WSL configuration
      daimyo00 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs outputs;};
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
              extraSpecialArgs = {inherit inputs outputs;};
            };
          }
        ];
      };

      # No CUDA/TensorRT configuration
      daimyo00-nocuda = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs;};
        modules = [
          # WSL module
          inputs.nixos-wsl.nixosModules.wsl

          # Base configuration
          ({
            pkgs,
            lib,
            ...
          }: {
            # Basic system configuration
            system.stateVersion = "24.05";

            # System configuration
            nixpkgs = {
              config = {
                allowUnfree = true;
                allowBroken = true;
                # Explicitly disable CUDA
                cudaSupport = false;
                cudaCapabilities = [];
              };
              # Ensure no CUDA overlays
              overlays = [];
            };

            # Disable all NVIDIA/CUDA related features
            hardware = {
              nvidia = {
                package = null;
                modesetting.enable = false;
              };
              nvidia-container-toolkit.enable = false;
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
                {src = "${coreutils}/bin/cat";}
                {src = "${coreutils}/bin/whoami";}
                {src = "${su}/bin/groupadd";}
                {src = "${su}/bin/usermod";}
              ];
            };

            # Disable NVIDIA container runtime in Docker instead
            virtualisation.docker = {
              enable = true;
              enableOnBoot = true;
              autoPrune.enable = true;
              # Disable NVIDIA runtime
              enableNvidia = false;
              extraOptions = "--add-runtime none=runc";
            };

            # Environment variables to prevent CUDA detection
            environment.variables = {
              CUDA_PATH = "";
              LD_LIBRARY_PATH = "";
              NVIDIA_DRIVER_CAPABILITIES = "";
              NVIDIA_VISIBLE_DEVICES = "none";
            };

            nix = {
              settings = {
                experimental-features = ["nix-command" "flakes" "auto-allocate-uids"];
                auto-optimise-store = true;
                trusted-users = ["root" "ryzengrind" "@wheel"];
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
                dates = ["weekly"];
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
              extraGroups = ["wheel" "docker" "audio" "networkmanager"];
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
              extraSpecialArgs = {inherit inputs;};
            };
          }
        ];
      };

      # Minimal test configuration
      daimyo00-test = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs;};
        modules = [
          # Bare minimum NixOS configuration
          ({pkgs, ...}: {
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
              substituters = ["https://cache.nixos.org"];
              trusted-public-keys = ["cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="];
              accept-flake-config = true;
              experimental-features = ["nix-command" "flakes"];
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
              extraGroups = ["wheel"];
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
        extraSpecialArgs = {inherit inputs outputs;};
        modules = [
          ./hosts/daimyo00/home.nix
        ];
      };
    };
  };
}
