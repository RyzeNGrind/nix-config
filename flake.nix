{
  description = "NixOS configuration with specialisations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    attic = {
      url = "github:zhaofengli/attic";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    nixos-wsl,
    hyprland,
    nixos-hardware,
    attic,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    inherit (nixpkgs) lib;

    # Helper function to create host configurations
    mkHost = {
      name,
      modules ? [],
      features ? [],
      profileConfig ? {},
    }:
      nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {inherit inputs features;};
        modules =
          [
            # Core modules
            ./modules/core
            {
              core = {
                enable = true;
                system.enable = true;
                network.enable = true;
                spec.enable = true;
              };

              # Profile configuration
              profiles =
                lib.recursiveUpdate {
                  # Base profile configuration for all systems
                  base = {
                    enable = true;
                    security.enable = true;
                    nix = {
                      enable = true;
                      gc = {
                        enable = true;
                        dates = "weekly";
                      };
                    };
                  };
                }
                profileConfig;
            }

            # Input modules
            home-manager.nixosModules.home-manager
            nixos-wsl.nixosModules.wsl
            hyprland.nixosModules.default
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.ryzengrind = import (./hosts + "/${name}/home.nix");
                extraSpecialArgs = {
                  inherit inputs;
                };
              };
              programs.hyprland = {
                enable = lib.mkDefault false;
                package = hyprland.packages.${system}.hyprland;
                xwayland.enable = true;
              };
            }

            # Profile system
            ./modules/profiles

            # Host-specific configuration
            (./hosts + "/${name}/configuration.nix")
          ]
          ++ modules;
      };
  in {
    # NixOS configurations
    nixosConfigurations = {
      daimyo = mkHost {
        name = "daimyo";
        features = ["desktop" "development" "gaming"];
        profileConfig = {
          workstation.enable = true;
          gaming = {
            enable = true;
            nvidia = true;
            amd = false;
            virtualization = {
              enable = false;
              looking-glass = false;
            };
          };
          development = {
            enable = true;
            ide = "vscodium";
            vscodeRemote = {
              enable = true;
              method = "nix-ld";
            };
            ml = {
              enable = true;
              cudaSupport = true;
              pytorch = {
                enable = true;
              };
            };
          };
        };
        modules = [
          # Base configuration
          {
            programs.hyprland.enable = lib.mkDefault false;
            environment.systemPackages = with pkgs; [
              hyprland.packages.${system}.hyprland
            ];
          }
          # Import Hyprland module
          hyprland.nixosModules.default
        ];
      };

      daimyo00 = mkHost {
        name = "daimyo00";
        features = ["minimal" "development"];
        profileConfig = {
          development = {
            enable = true;
            ide = "vscodium";
            vscodeRemote = {
              enable = true;
              method = "nix-ld";
            };
            ml = {
              enable = false;
              cudaSupport = false;
              pytorch = {
                enable = false;
              };
            };
          };
          wsl.enable = true;
        };
        modules = [nixos-wsl.nixosModules.wsl];
      };
    };

    # Tests
    nixosTests = {
      core = pkgs.nixosTest {
        name = "core-system-test";
        nodes.machine = import ./tests/core/default.nix;
        testScript = builtins.readFile ./tests/core/test.py;
      };

      specialisation = pkgs.nixosTest {
        name = "specialisation-test";
        nodes.machine = import ./tests/specialisation/default.nix;
        testScript = builtins.readFile ./tests/specialisation/test.py;
      };

      profiles = pkgs.nixosTest {
        name = "profile-test";
        nodes = import ./tests/profiles/default.nix;
      };

      wsl = pkgs.nixosTest {
        name = "wsl-test";
        nodes = import ./tests/wsl/default.nix;
      };

      # Integration test that runs all tests
      all = pkgs.nixosTest {
        name = "integration-test";
        nodes.machine = {
          config,
          pkgs,
          ...
        }: {
          imports = [
            ./tests/default.nix
          ];
          testing = {
            enable = true;
            levels = {
              unit = true;
              integration = true;
              system = true;
            };
            coverage.enable = true;
          };
        };
      };
    };

    # Checks
    checks.${system} = {
      test-core = self.nixosTests.core.driver;
      test-specialisation = self.nixosTests.specialisation.driver;
      test-profiles = self.nixosTests.profiles.driver;
      test-wsl = self.nixosTests.wsl.driver;
      test-all = self.nixosTests.all.driver;
      format = pkgs.runCommand "check-format" {} ''
        ${pkgs.alejandra}/bin/alejandra --check ${./.}
        touch $out
      '';
      statix = pkgs.runCommand "check-statix" {} ''
        ${pkgs.statix}/bin/statix check ${./.}
        touch $out
      '';
    };

    # Development shell with testing support
    devShells.${system}.default = pkgs.mkShell {
      buildInputs = with pkgs; [
        nixfmt
        statix
        nil
        alejandra
        pre-commit
        python3Packages.pytest
        python3Packages.pytest-xdist
        python3Packages.pytest-cov
      ];
      shellHook = ''
        echo "Development environment ready"
        echo "Run 'nix flake check' to run all tests"
      '';
    };

    # Formatter
    formatter.${system} = pkgs.alejandra;
  };
}
