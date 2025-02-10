{
  description = "NixOS configuration with specialisations";

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

    # Development shell
    devShells = forAllSystems (system: {
      default = nixpkgs.legacyPackages.${system}.mkShell {
        buildInputs = with nixpkgs.legacyPackages.${system}; [
          alejandra
          deadnix
          statix
          nodePackages.prettier
          pre-commit
        ];
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

    # Custom packages
    packages = forAllSystems (system: {
      default = nixpkgs.legacyPackages.${system}.hello;
    });

    # Formatter
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

    # Overlays
    overlays = import ./overlays {inherit inputs;} // {unstable = overlayUnstable;};

    # NixOS modules
    nixosModules = import ./modules/nixos;

    # NixOS configurations
    nixosConfigurations = {
      # Single configuration with specialisations
      daimyo = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs outputs;};
        modules = [
          # Base configuration
          ./hosts/base/default.nix

          # Global settings
          {
            nixpkgs.config = {
              allowUnfree = true;
              allowBroken = true;
            };

            # Nix settings
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
                experimental-features = ["nix-command" "flakes"];
              };
            };

            # Specialisations
            specialisation = {
              # WSL with CUDA
              wsl-cuda = {
                inheritParentConfig = true;
                configuration = {
                  imports = [
                    nixos-wsl.nixosModules.wsl
                    ./hosts/daimyo/wsl-cuda.nix
                  ];
                  wsl = {
                    enable = true;
                    nativeSystemd = true;
                    cuda.enable = true;
                  };
                };
              };

              # WSL without CUDA
              wsl-nocuda = {
                inheritParentConfig = true;
                configuration = {
                  imports = [
                    nixos-wsl.nixosModules.wsl
                    ./hosts/daimyo/wsl-nocuda.nix
                  ];
                  wsl = {
                    enable = true;
                    nativeSystemd = true;
                    cuda.enable = false;
                  };
                };
              };

              # Baremetal
              baremetal = {
                inheritParentConfig = true;
                configuration = {
                  imports = [
                    ./hosts/daimyo/baremetal.nix
                  ];
                  wsl.enable = false;
                  hardware.nvidia.enable = true;
                };
              };
            };
          }

          # Home Manager
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.ryzengrind = import ./hosts/daimyo/home.nix;
              extraSpecialArgs = {inherit inputs outputs;};
            };
          }
        ];
      };
    };

    # Home-manager configurations
    homeConfigurations = {
      "ryzengrind@daimyo" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        extraSpecialArgs = {inherit inputs outputs;};
        modules = [
          ./hosts/daimyo/home.nix
        ];
      };
    };
  };
}
